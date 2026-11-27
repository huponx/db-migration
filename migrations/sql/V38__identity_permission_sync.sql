-- The permission catalog is now written by the services at their start (identity syncs its own file and the
-- permissions of services without a process, the others call RegisterPermissions), not by administrators.
--   service     the service that defines the permission ("identity"); '' for a row nobody claims
--   retired_at  set when a service stopped declaring a permission that a role still holds; a retired permission is
--               not enforced, not in tokens and hidden from the role editor, the grants of the roles stay
ALTER TABLE identity_permissions
    ADD COLUMN service    text        NOT NULL DEFAULT '',
    ADD COLUMN retired_at timestamptz;

-- adopt the existing rows: the first sync of each service takes them over
UPDATE identity_permissions SET service = split_part(permission, ':', 1)
WHERE split_part(permission, ':', 1) IN ('identity', 'dictionary', 'bill', 'system') AND permission NOT LIKE '%*%';

-- Wildcards are not stored: identity generates them from the declared permissions. A role keeps whatever wildcard
-- it holds ('*' of admin, 'identity:*:read' of viewer): both are generated ones, so nothing changes for them.
-- The foreign key goes first, a role may hold a name that is not a row (a wildcard, a permission of a service that
-- left); SetRolePermissions checks names against the catalog and the generated wildcards instead.
ALTER TABLE identity_role_permissions DROP CONSTRAINT IF EXISTS identity_role_permissions_permission_fkey;
DELETE FROM identity_permissions WHERE permission LIKE '%*%';

CREATE INDEX identity_permissions_service_idx ON identity_permissions (service);

-- Services register their permissions at start (RegisterPermissions); give a service client this role in the
-- SETUP_CONFIG of identity ("roles": ["service_registrar"]). The permission is declared by identity's own file at its
-- next start; roles do not need a catalog row to hold a name.
INSERT INTO identity_roles (name, description) VALUES
    ('service_registrar', 'A service client that registers its permissions at start')
ON CONFLICT DO NOTHING;

INSERT INTO identity_role_permissions (role, permission) VALUES
    ('service_registrar', 'identity:permission:register')
ON CONFLICT DO NOTHING;
