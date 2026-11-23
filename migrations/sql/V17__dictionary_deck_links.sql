-- Anki decks waiting to be downloaded through a link (dictionary service, "import from a link" of an Anki
-- app). The link carries a random token; only its SHA-256 is stored. A user has one link at a time, the
-- download deletes the row, and the service deletes the rows that expired.
CREATE TABLE dictionary_deck_links (
    token_hash bytea       PRIMARY KEY,
    user_id    uuid        NOT NULL UNIQUE REFERENCES identity_users (id) ON DELETE CASCADE,
    filename   text        NOT NULL,
    data       bytea       NOT NULL,
    word_count integer     NOT NULL,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- The cleanup of expired links.
CREATE INDEX dictionary_deck_links_expires_idx ON dictionary_deck_links (expires_at);
