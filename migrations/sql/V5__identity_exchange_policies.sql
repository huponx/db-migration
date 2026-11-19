-- Which client may obtain tokens for which audience, by token exchange (RFC 8693) or by
-- client_credentials. No row means denied.
CREATE TABLE identity_exchange_policies (
    client_id       text     NOT NULL REFERENCES identity_clients (client_id) ON DELETE CASCADE,
    audience        text     NOT NULL,
    -- space separated scopes the issued token may carry at most
    max_scope       text     NOT NULL DEFAULT '',
    max_chain_depth integer  NOT NULL DEFAULT 1 CHECK (max_chain_depth BETWEEN 1 AND 5),
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (client_id, audience)
);
