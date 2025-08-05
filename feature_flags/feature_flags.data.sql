INSERT INTO flags (name) VALUES
  ('enable_dark_mode'),
  ('show_ads'),
  ('new_ui'),
  ('require_2fa'),
  ('experimental_search'),
  ('hide_comments');

INSERT INTO domains (hostname) VALUES
  ('example.com'),
  ('demo.net');

INSERT INTO domain_flags (domain_id, flag_id, status, env) VALUES
  (1, 1, 'on',  'dev'), (1, 1, 'on',  'staging'), (1, 1, 'off', 'prod'),
  (1, 3, 'on',  'dev'), (1, 3, 'off', 'staging'), (1, 3, 'off', 'prod'),
  (1, 4, 'off', 'dev'), (1, 4, 'off', 'staging'), (1, 4, 'on',  'prod'),
  (2, 2, 'on',  'dev'), (2, 2, 'on',  'staging'), (2, 2, 'off', 'prod'),
  (2, 3, 'on',  'dev'), (2, 3, 'off', 'staging'), (2, 3, 'off', 'prod'),
  (2, 5, 'on',  'dev'), (2, 4, 'on',  'staging'), (2, 5, 'off', 'prod');
