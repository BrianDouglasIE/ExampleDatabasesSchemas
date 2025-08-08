-- create user with encrypted password (DONE) => create_new_user(user_email, user_password)
-- update user password                (DONE) => update_user_password(user_id, old_password, new_password)
-- check passwords match               (DONE) => is_correct_user_password(user_id, user_password)
-- create token for user               (DONE) => create_token_for_user(user_id, user_password)
-- get latest valid token for user     (DONE) => get_latest_active_token(user_id)
-- expire out of date tokens           (DONE) => expire_active_tokens(user_id)
-- revoke user tokens                  (DONE) => revoke_active_tokens(user_id)

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
	NEW.updated_at = CURRENT_TIMESTAMP;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

-- users

CREATE TABLE IF NOT EXISTS users (
	id SERIAL PRIMARY KEY,
	email TEXT NOT NULL UNIQUE,
	password CHAR(60) NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER set_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE VIEW user_view AS
SELECT id, email, created_at, updated_at
FROM users;

CREATE OR REPLACE FUNCTION create_new_user(_email TEXT, _pw TEXT)
RETURNS TABLE (
    id INT,
    email TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
	RETURN QUERY
	INSERT INTO users (email, password)
	VALUES (_email, crypt(_pw, gen_salt('bf')))
	RETURNING users.id, users.email, users.created_at, users.updated_at;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_correct_user_password(_user_id INT, _user_pw TEXT)
RETURNS BOOL AS $$
DECLARE
	stored_hash TEXT;
BEGIN
	SELECT password INTO stored_hash
	FROM users
	WHERE id = _user_id;

	IF stored_hash IS NULL THEN
		RETURN FALSE;
	END IF;

	RETURN crypt(_user_pw, stored_hash) = stored_hash;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_user_password(_user_id INT, _old_pw TEXT, _new_pw TEXT)
RETURNS void AS $$
DECLARE
	password_match BOOL;
BEGIN
	SELECT is_correct_user_password(_user_id, _old_pw) INTO password_match;
	
	IF password_match = FALSE THEN
		RAISE EXCEPTION 'Invalid password';
	END IF;

	UPDATE users
	SET password = crypt(_new_pw, gen_salt('bf'))
	WHERE id = _user_id;

	UPDATE tokens
	SET state = 'revoked'
	WHERE user_id = _user_id
	  AND state = 'active';
END;
$$ LANGUAGE plpgsql;

-- tokens

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'token_state'
    ) THEN
        CREATE TYPE token_state AS ENUM ('active', 'revoked', 'expired');
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS tokens (
	id SERIAL PRIMARY KEY,
	user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	token TEXT,
	state token_state DEFAULT 'active'::token_state,
	expires_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP + '3 days',
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER set_tokens_updated_at
BEFORE UPDATE ON tokens
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE VIEW token_view AS
SELECT id, user_id, token, state, expires_at, created_at, updated_at
FROM tokens;

CREATE OR REPLACE FUNCTION get_latest_active_token(_user_id INT)
RETURNS SETOF token_view AS $$
BEGIN
	RETURN QUERY
	SELECT * FROM token_view
	WHERE user_id = _user_id
	  AND state = 'active'
	  AND expires_at > CURRENT_TIMESTAMP
	  ORDER BY created_at DESC
	  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION login(_user_id INT, _user_pw TEXT)
RETURNS TABLE (
    id INT,
    user_id INT,
	token TEXT,
	state token_state,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
DECLARE
	password_match BOOL;
	recent_failed_attempts INT;
BEGIN
	SELECT failed_login_count(_user_id, '10 minutes') INTO recent_failed_attempts;

	IF recent_failed_attempts >= 3 THEN
		RAISE EXCEPTION 'Too many failed attempts' USING ERRCODE = 'P0001';
	END IF;

	SELECT is_correct_user_password(_user_id, _user_pw) INTO password_match;
	
	IF password_match = FALSE THEN
		RAISE EXCEPTION 'Invalid password' USING ERRCODE = 'P0001';
	END IF;

	RETURN QUERY
	INSERT INTO tokens (user_id, token)
	VALUES (_user_id, encode(gen_random_bytes(32), 'hex'))
	RETURNING 
		tokens.id,
		tokens.user_id,
		tokens.token,
		tokens.state,
		tokens.expires_at,
		tokens.created_at,
		tokens.updated_at;
EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE 'Login failed: %', SQLERRM;
		INSERT INTO user_failed_logins (user_id)
		VALUES (_user_id);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION expire_active_tokens(_user_id INT)
RETURNS void AS $$
BEGIN
	UPDATE tokens
	SET state = 'expired'
	WHERE user_id = _user_id
	  AND state = 'active'
	  AND expires_at > CURRENT_TIMESTAMP;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION revoke_active_tokens(_user_id INT)
RETURNS void AS $$
BEGIN
	UPDATE tokens
	SET state = 'revoked'
	WHERE user_id = _user_id
	  AND state = 'active';
END
$$ LANGUAGE plpgsql;

-- failed login attempts

CREATE TABLE IF NOT EXISTS user_failed_logins (
	id SERIAL PRIMARY KEY,
	user_id INT REFERENCES users(id) ON DELETE CASCADE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION failed_login_count(_user_id INT, _interval TEXT)
RETURNS INT AS $$
DECLARE
	failed_attempts INT;
BEGIN
	SELECT COUNT(id) INTO failed_attempts
	FROM user_failed_logins
	WHERE user_id = _user_id
	  AND created_at > CURRENT_TIMESTAMP - _interval::interval;
	
	RETURN failed_attempts;
END
$$ LANGUAGE plpgsql;

-- queries

-- SELECT * FROM create_new_user('emma@gmail.com', 'secret');
-- SELECT * FROM user_view;
-- SELECT * FROM is_correct_user_password(1, 'secret1');
SELECT * FROM login(1, 'secret');
-- SELECT * FROM user_failed_logins;

-- SELECT * FROM failed_login_count(1, '20 minutes');
-- SELECT * FROM get_latest_active_token(1);
-- SELECT * FROM update_user_password(1, 'password', 'secret');
-- SELECT * FROM revoke_active_tokens(1);
-- SELECT * FROM tokens;
