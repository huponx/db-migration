-- Lookups by the second column of a composite primary key, which the key cannot serve:
--  * identity_user_roles / identity_client_roles by role: the assigned count of every role in ListRoles, the
--    "role in use" checks, and the ON DELETE CASCADE from identity_roles
--  * identity_role_permissions by permission: the role count of every permission in ListPermissions and the
--    foreign key to identity_permissions (a delete of a permission looks for the roles that hold it)
-- The keyset (page token) columns need nothing: identity_users.email (unique index), identity_roles.name,
-- identity_permissions.permission, identity_clients.client_id and (client_id, audience) of the exchange
-- policies are primary keys or unique.
CREATE INDEX IF NOT EXISTS identity_user_roles_role_idx ON identity_user_roles (role);
CREATE INDEX IF NOT EXISTS identity_client_roles_role_idx ON identity_client_roles (role);
CREATE INDEX IF NOT EXISTS identity_role_permissions_permission_idx ON identity_role_permissions (permission);
