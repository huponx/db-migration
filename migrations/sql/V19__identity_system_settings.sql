-- Settings of identity for the whole system, one row per setting (a new setting needs no migration): today
-- the look of the web apps ('ui_style'). A key without a row takes its default from the code, so an empty
-- table behaves as before.
CREATE TABLE identity_system_settings (
    key        text        PRIMARY KEY,
    value      jsonb       NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Who may change the system settings (the admin app); an admin holding "*" has them already.
INSERT INTO identity_permissions (permission, description) VALUES
    ('identity:settings:read', 'See the system settings of identity (look of the web apps)'),
    ('identity:settings:write', 'Change the system settings of identity (look of the web apps)')
ON CONFLICT DO NOTHING;
