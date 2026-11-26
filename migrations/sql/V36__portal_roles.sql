-- Roles for the portal (root domain): "member" is the default role of a self-registered account (see
-- IDENTITY_REGISTRATION_ROLE of identity), "billing" opens the bill app. The permissions must be in the catalog
-- before a role is given them. Profile and password of one's own account need no permission (public routes).
INSERT INTO identity_permissions (permission, description) VALUES
    ('bill:invoice:read', 'See the invoices of the bill app'),
    ('dictionary:word:read', 'Look words up and list the saved words'),
    ('dictionary:word:write', 'Save and delete words, export them as an Anki deck')
ON CONFLICT DO NOTHING;

INSERT INTO identity_roles (name, description) VALUES
    ('member', 'Default role of a self-registered account: uses the dictionary'),
    ('billing', 'Sees the invoices of the bill app')
ON CONFLICT DO NOTHING;

INSERT INTO identity_role_permissions (role, permission) VALUES
    ('member', 'dictionary:word:read'),
    ('member', 'dictionary:word:write'),
    ('billing', 'bill:invoice:read')
ON CONFLICT DO NOTHING;
