-- Settings of the dictionary service for the whole system, one row per setting (a new setting needs no
-- migration): the service reads all rows into a typed struct, a key without a row takes its default
-- from the code, so an empty table behaves as before.
CREATE TABLE dictionary_settings (
    key        text        PRIMARY KEY,
    value      jsonb       NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Settings of one user for one application (identity owns the users, so it owns this table). `app` is the
-- short name of the application ('dictionary'), `settings` is whatever that application stores: identity does
-- not look inside, the application validates what it writes.
CREATE TABLE identity_user_settings (
    user_id    uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    app        text        NOT NULL CHECK (app ~ '^[a-z][a-z0-9_-]{0,31}$'),
    settings   jsonb       NOT NULL DEFAULT '{}',
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, app),
    CONSTRAINT identity_user_settings_object CHECK (jsonb_typeof(settings) = 'object')
);

-- Who may read and change the settings of the dictionary (the admin app); an admin holding "*" has them already.
INSERT INTO identity_permissions (permission, description) VALUES
    ('dictionary:settings:read', 'See the settings of the dictionary (limits, export, dictionaries)'),
    ('dictionary:settings:write', 'Change the settings of the dictionary')
ON CONFLICT DO NOTHING;
