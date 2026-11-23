-- The catalog of permissions a role can be given. Wildcards are entries like any other ("*",
-- "identity:*:read"), see gocommon/authz for how they match. A role can only hold permissions that
-- are in the catalog; a permission that a role holds cannot be deleted.
CREATE TABLE identity_permissions (
    permission  text PRIMARY KEY CHECK (permission ~ '^(\*|(\*|[a-z0-9_.-]+)(:(\*|[a-z0-9_.-]+))*)$'),
    description text        NOT NULL DEFAULT '',
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- what the identity service itself checks
INSERT INTO identity_permissions (permission, description) VALUES
    ('*',                          'Everything'),
    ('identity:*:read',            'Read everything in identity'),
    ('identity:user:read',         'List and read users'),
    ('identity:user:write',        'Create and edit users, send welcome and reset emails'),
    ('identity:role:read',         'List roles'),
    ('identity:role:write',        'Create roles and change what they allow, assign roles'),
    ('identity:permission:read',   'List the permission catalog'),
    ('identity:permission:write',  'Add, describe and delete permissions of the catalog'),
    ('identity:client:read',       'List clients'),
    ('identity:client:write',      'Create clients and rotate their secrets'),
    ('identity:exchange:read',     'List token exchange policies'),
    ('identity:exchange:write',    'Set and delete token exchange policies'),
    ('identity:mfa:read',          'Read the multi-factor state of users'),
    ('identity:mfa:write',         'Change the multi-factor settings of users'),
    ('identity:token:read',        'Introspect tokens'),
    ('identity:token:write',       'Revoke tokens')
ON CONFLICT DO NOTHING;

-- whatever roles already hold (other services have their own permissions)
INSERT INTO identity_permissions (permission)
SELECT DISTINCT permission FROM identity_role_permissions
ON CONFLICT DO NOTHING;

ALTER TABLE identity_role_permissions
    ADD CONSTRAINT identity_role_permissions_permission_fkey
    FOREIGN KEY (permission) REFERENCES identity_permissions (permission)
    ON UPDATE CASCADE ON DELETE RESTRICT;
