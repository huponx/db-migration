-- mfa_enabled: the user enrolled and confirmed a factor and is asked for it at login.
-- mfa_enforced: an admin requires MFA for this user, the user cannot turn it off.
ALTER TABLE identity_users
    ADD COLUMN mfa_enabled  boolean NOT NULL DEFAULT false,
    ADD COLUMN mfa_enforced boolean NOT NULL DEFAULT false;

CREATE TABLE identity_user_mfa_factors (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    type           text        NOT NULL CHECK (type IN ('totp')),
    -- AES-GCM sealed secret (key id + nonce + ciphertext)
    secret_sealed  bytea       NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    -- NULL until the user typed the first valid code
    confirmed_at   timestamptz,
    -- time step of the last accepted code, a code of the same or an older step is refused
    last_used_step bigint      NOT NULL DEFAULT 0
);

-- one factor per user and type; an unconfirmed enrollment is replaced by a new one
CREATE UNIQUE INDEX identity_user_mfa_factors_user_type_key ON identity_user_mfa_factors (user_id, type);

CREATE TABLE identity_mfa_recovery_codes (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id   uuid  NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    code_hash bytea NOT NULL,
    used_at   timestamptz
);

CREATE INDEX identity_mfa_recovery_codes_user_idx ON identity_mfa_recovery_codes (user_id);
CREATE UNIQUE INDEX identity_mfa_recovery_codes_hash_key ON identity_mfa_recovery_codes (user_id, code_hash);
