-- Read the status of the applications (ArgoCD) in the admin app. Checked by gatekeeper itself
-- (GET /api/system/status), so it is a permission of the catalog like those of identity; an admin
-- holding "*" has it already.
INSERT INTO identity_permissions (permission, description) VALUES
    ('system:status:read', 'See the status of the applications (ArgoCD) on the admin home page')
ON CONFLICT DO NOTHING;
