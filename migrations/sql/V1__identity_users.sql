CREATE TABLE identity_users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         text        NOT NULL,
    name          text        NOT NULL DEFAULT '',
    locale        text        NOT NULL DEFAULT 'en',
    -- argon2id PHC string; NULL until the user sets a password (password reset flow)
    password_hash text,
    password_changed_at timestamptz,
    disabled      boolean     NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT identity_users_email_lower CHECK (email = lower(email))
);

CREATE UNIQUE INDEX identity_users_email_key ON identity_users (email);
