CREATE TABLE identity_clients (
    client_id                 text PRIMARY KEY,
    name                      text        NOT NULL,
    type                      text        NOT NULL CHECK (type IN ('public', 'confidential')),
    -- hex SHA-256 of the secret (random, 256 bits, so no slow hash needed); NULL for a public client
    secret_hash               text,
    redirect_uris             text[]      NOT NULL DEFAULT '{}',
    post_logout_redirect_uris text[]      NOT NULL DEFAULT '{}',
    backchannel_logout_uri    text        NOT NULL DEFAULT '',
    allowed_grants            text[]      NOT NULL DEFAULT '{authorization_code,refresh_token}',
    allowed_scopes            text[]      NOT NULL DEFAULT '{openid,profile,email,offline_access}',
    -- default audience of the tokens issued to this client
    resource                  text        NOT NULL,
    access_token_ttl_seconds  integer,
    disabled                  boolean     NOT NULL DEFAULT false,
    created_at                timestamptz NOT NULL DEFAULT now(),
    updated_at                timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT identity_clients_secret CHECK ((type = 'confidential') = (secret_hash IS NOT NULL))
);
