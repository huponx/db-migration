-- A service client that only looks users up (courier resolves the e-mail, name and language of the users an event is
-- addressed to, and lists the audience of an announcement). Give it to the client in the SETUP_CONFIG of identity
-- ("roles": ["service_registrar", "user_directory"]). Roles need no catalog row to hold a permission name.
INSERT INTO identity_roles (name, description) VALUES
    ('user_directory', 'A service client that reads users (GetUser, ListUsers) to address its messages')
ON CONFLICT DO NOTHING;

INSERT INTO identity_role_permissions (role, permission) VALUES
    ('user_directory', 'identity:user:read')
ON CONFLICT DO NOTHING;
