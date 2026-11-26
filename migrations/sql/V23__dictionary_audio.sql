-- Audio files of the cards (dictionary service), like the images of V21. The bytes are files on a volume
-- (<dir>/audio/<user_id>/<id>.<ext>); audio_uk / audio_us of a saved word refer to one as dictaud:<id>.
CREATE TABLE dictionary_audio (
    id           uuid        PRIMARY KEY,
    user_id      uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    content_type text        NOT NULL,
    -- bytes of the file (the quota of a user is the sum)
    size         integer     NOT NULL,
    -- the same file of one user is stored once
    sha256       bytea       NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, sha256)
);

CREATE INDEX dictionary_audio_user_idx ON dictionary_audio (user_id);
CREATE INDEX dictionary_audio_created_idx ON dictionary_audio (created_at);

-- Which audio files a saved word uses; SaveWord rewrites the set in its own transaction, so the cleanup finds
-- the unused files without reading any card.
CREATE TABLE dictionary_audio_refs (
    user_id  uuid NOT NULL,
    word     text NOT NULL,
    audio_id uuid NOT NULL REFERENCES dictionary_audio (id),
    PRIMARY KEY (user_id, word, audio_id),
    FOREIGN KEY (user_id, word) REFERENCES dictionary_saved_words (user_id, word) ON DELETE CASCADE
);

CREATE INDEX dictionary_audio_refs_audio_idx ON dictionary_audio_refs (audio_id);
