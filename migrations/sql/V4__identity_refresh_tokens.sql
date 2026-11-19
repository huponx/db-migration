-- Refresh tokens are opaque; only the SHA-256 of the token is stored. Every use rotates the
-- token inside its family; presenting a used token revokes the family.
CREATE TABLE identity_refresh_tokens (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id   uuid        NOT NULL,
    token_hash  bytea       NOT NULL,
    user_id     uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    client_id   text        NOT NULL REFERENCES identity_clients (client_id) ON DELETE CASCADE,
    -- identity session (sid) the token belongs to; NULL for tokens without an SSO session
    session_id  text,
    scope       text        NOT NULL,
    auth_time   timestamptz NOT NULL,
    amr         text[]      NOT NULL DEFAULT '{}',
    created_at  timestamptz NOT NULL DEFAULT now(),
    expires_at  timestamptz NOT NULL,
    used_at     timestamptz,
    revoked_at  timestamptz
);

CREATE UNIQUE INDEX identity_refresh_tokens_hash_key ON identity_refresh_tokens (token_hash);
CREATE INDEX identity_refresh_tokens_family_idx ON identity_refresh_tokens (family_id);
CREATE INDEX identity_refresh_tokens_user_idx ON identity_refresh_tokens (user_id);
CREATE INDEX identity_refresh_tokens_session_idx ON identity_refresh_tokens (session_id) WHERE session_id IS NOT NULL;
CREATE INDEX identity_refresh_tokens_expires_idx ON identity_refresh_tokens (expires_at);
