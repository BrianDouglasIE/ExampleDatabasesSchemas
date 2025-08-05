# Feature Flags

Feature flags are simple _on_ / _off_ flags that can be used to toggle application features without needing a production release.

This implementation allows for flags that are domain specific. Each flag can have a different status based on the current environment.
For example the flag `enable_dark_mode` on the domain `example.com` may be `on` in `staging` and `off` in `production`.

## Set Up

```sql
createdb feature_flags
psql -d feature_flags -f feature_flags.schema.sql
psql -d feature_flags -f feature_flags.data.sql
```

## Example Queries

### Get a specific flag on staging for a given domain

```sql
SELECT
  d.hostname,
  f.name AS flag,
  df.status,
  df.environment,
  f.updated_at
FROM flags f
JOIN domain_flags df ON f.id = df.flag_id
JOIN domains d ON d.id = df.domain_id
WHERE d.hostname = 'example.com'
  AND df.environment = 'staging'
  AND f.name = 'enable_dark_mode';
```

```
  hostname   |       flag       | status | environment |          updated_at
-------------+------------------+--------+-------------+-------------------------------
 example.com | enable_dark_mode | on     | staging     | 2025-08-05 08:10:01.471816+00
(1 row)
```

### Get all active flags on prod for a given domain

```sql
SELECT
  d.hostname,
  f.name AS flag,
  df.status,
  f.updated_at
FROM flags f
JOIN domain_flags df ON f.id = df.flag_id
JOIN domains d ON d.id = df.domain_id
WHERE d.hostname = 'example.com'
  AND df.environment = 'prod'
  AND df.status = 'on';
```

```
  hostname   |    flag     | status |          updated_at
-------------+-------------+--------+-------------------------------
 example.com | require_2fa | on     | 2025-08-05 08:10:01.471816+00
(1 row)
```

### Get status of all flags on all environments for a given domain

```sql
SELECT
  f.name AS flag,
  df.status,
  df.environment
FROM flags f
JOIN domain_flags df ON f.id = df.flag_id
JOIN domains d ON d.id = df.domain_id
WHERE d.hostname = 'example.com';
```

```
       flag       | status | environment
------------------+--------+-------------
 enable_dark_mode | on     | dev
 enable_dark_mode | on     | staging
 enable_dark_mode | off    | prod
 new_ui           | on     | dev
 new_ui           | off    | staging
 new_ui           | off    | prod
 require_2fa      | off    | dev
 require_2fa      | off    | staging
 require_2fa      | on     | prod
(9 rows)
```

## Enums

```sql
CREATE TYPE flag_status AS ENUM ('on', 'off');
CREATE TYPE environment AS ENUM ('dev', 'staging', 'prod');
```