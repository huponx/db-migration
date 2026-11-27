-- Self-registered users can wait for the approval of an administrator (system setting registration_requires_approval of
-- identity). While the flag is set the user has no welcome or reset link and cannot set a password.
ALTER TABLE identity_users ADD COLUMN IF NOT EXISTS pending_approval boolean NOT NULL DEFAULT false;

INSERT INTO identity_permissions (permission, description) VALUES
    ('identity:user:approve', 'Approve or reject self-registered users')
ON CONFLICT DO NOTHING;

-- user_approver reads the users (to open the Users page and see who waits) and decides on the requests; it has no write access.
INSERT INTO identity_roles (name, description) VALUES
    ('user_approver', 'Only approves or rejects self-registered users')
ON CONFLICT DO NOTHING;

INSERT INTO identity_role_permissions (role, permission) VALUES
    ('user_approver', 'identity:user:approve'),
    ('user_approver', 'identity:user:read')
ON CONFLICT DO NOTHING;
