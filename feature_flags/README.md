# Feature Flags

Feature flags are simple _on_ / _off_ flags that can be used to toggle application features without needing a production release.

This implementation allows for flags that are domain specific. This is helpful if you have multiple environments, for example _dev_, _staging_, _prod_ etc...,
and want to test that the code surrounding a feature flag is working correctly.

## Set Up

```sql
createdb feature_flags
psql -d feature_flags -f feature_flags.schema.sql
psql -d feature_flags -f feature_flags.data.sql
```

## Example Queries

### Get all flags for a given domain

*By `hostname`:*

```sql
SELECT f.*
FROM flags f
JOIN domain_flags df ON f.id = df.flag_id
JOIN domains d ON df.domain_id = d.id
WHERE d.hostname = 'example.com';
```

```
 id |       name       | status |          created_at           |          updated_at
----+------------------+--------+-------------------------------+-------------------------------
  1 | enable_dark_mode | on     | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
  3 | maintenance_mode | off    | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
  5 | new_ui           | on     | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
(3 rows)
```

*By `domain_id`:*

```sql
SELECT f.*
FROM flags f
JOIN domain_flags df ON f.id = df.flag_id
WHERE df.domain_id = 1;
```

```
 id |       name       | status |          created_at           |          updated_at
----+------------------+--------+-------------------------------+-------------------------------
  1 | enable_dark_mode | on     | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
  3 | maintenance_mode | off    | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
  5 | new_ui           | on     | 2025-08-05 06:44:39.328826+00 | 2025-08-05 06:44:39.328826+00
(3 rows)
```