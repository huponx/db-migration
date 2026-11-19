CREATE TABLE identity_roles (
    name        text PRIMARY KEY CHECK (name ~ '^[a-z][a-z0-9_.-]*$'),
    description text        NOT NULL DEFAULT '',
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- permission: colon separated segments ("invoice:read", "identity:user:write"); "*" is a
-- wildcard segment (see gocommon/authz)
CREATE TABLE identity_role_permissions (
    role       text NOT NULL REFERENCES identity_roles (name) ON DELETE CASCADE,
    permission text NOT NULL CHECK (permission ~ '^(\*|(\*|[a-z0-9_.-]+)(:(\*|[a-z0-9_.-]+))*)$'),
    PRIMARY KEY (role, permission)
);

CREATE TABLE identity_user_roles (
    user_id uuid NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    role    text NOT NULL REFERENCES identity_roles (name) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role)
);

CREATE TABLE identity_client_roles (
    client_id text NOT NULL REFERENCES identity_clients (client_id) ON DELETE CASCADE,
    role      text NOT NULL REFERENCES identity_roles (name) ON DELETE CASCADE,
    PRIMARY KEY (client_id, role)
);

INSERT INTO identity_roles (name, description) VALUES
    ('admin', 'Full access'),
    ('viewer', 'Read only access to identity');

INSERT INTO identity_role_permissions (role, permission) VALUES
    ('admin', '*'),
    ('viewer', 'identity:*:read');
