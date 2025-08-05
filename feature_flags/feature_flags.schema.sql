-- createdb feature_flags
-- psql -d feature_flags -f feature_flags.schema.sql
-- psql -d feature_flags -f feature_flags.data.sql

-- FUNCTIONS

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
	NEW.updated_at = CURRENT_TIMESTAMP;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

-- ENUMS

CREATE TYPE flag_status AS ENUM ('on', 'off');

-- TABLES

CREATE TABLE IF NOT EXISTS flags (
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL UNIQUE,
	status flag_status DEFAULT 'off',
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER set_flags_updated_at
BEFORE UPDATE ON flags
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS domains (
	id SERIAL PRIMARY KEY,
	hostname TEXT NOT NULL UNIQUE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER set_domains_updated_at
BEFORE UPDATE ON domains
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS domain_flags (
	domain_id INT NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
	flag_id INT NOT NULL REFERENCES flags(id) ON DELETE CASCADE,
	PRIMARY KEY (domain_id, flag_id)
);

-- INDICES

CREATE INDEX idx_domain_flags_domain_id ON domain_flags(domain_id);
CREATE INDEX idx_domain_flags_flag_id ON domain_flags(flag_id);
