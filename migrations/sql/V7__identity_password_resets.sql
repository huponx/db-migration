-- Password reset tokens: 256-bit random, only the SHA-256 is stored, single use. A new request
-- for a user invalidates the older ones (the application sets used_at).
CREATE TABLE identity_password_resets (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    token_hash   bytea       NOT NULL,
    requested_ip inet,
    created_at   timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL,
    used_at      timestamptz
);

CREATE UNIQUE INDEX identity_password_resets_hash_key ON identity_password_resets (token_hash);
CREATE INDEX identity_password_resets_user_idx ON identity_password_resets (user_id);
