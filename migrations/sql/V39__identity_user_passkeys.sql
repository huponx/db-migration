-- Passkeys (WebAuthn credentials) of a user, a sign in method next to the password. The public key needs no
-- sealing (unlike the TOTP secret). The WebAuthn user handle is the user id, so nothing here names the person.
--   credential_id  what the authenticator calls the key; unique across all users
--   sign_count     the counter of the authenticator (0 when it has none); a value that goes backwards is refused
--   backup_*       the BE/BS flags: a synced passkey is backup eligible
CREATE TABLE identity_user_passkeys (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    credential_id    bytea       NOT NULL UNIQUE,
    public_key       bytea       NOT NULL,
    sign_count       bigint      NOT NULL DEFAULT 0,
    aaguid           bytea       NOT NULL DEFAULT ''::bytea,
    transports       text[]      NOT NULL DEFAULT '{}',
    backup_eligible  boolean     NOT NULL DEFAULT false,
    backup_state     boolean     NOT NULL DEFAULT false,
    attestation_type text        NOT NULL DEFAULT 'none',
    name             text        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
    created_at       timestamptz NOT NULL DEFAULT now(),
    last_used_at     timestamptz
);

CREATE INDEX identity_user_passkeys_user_idx ON identity_user_passkeys (user_id);
