-- Words a user saved while looking them up (dictionary service). A row is "pending" while exported_at is
-- NULL: the pending rows are the next Anki export and count against the per-user limit. An export sets
-- exported_at on the rows it packed (a new batch starts), and the service deletes the rows exported
-- longer ago than its retention.
CREATE TABLE dictionary_saved_words (
    user_id     uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    word        text        NOT NULL,
    -- card back (HTML), with the placeholders replace_audio_uk / replace_audio_us for the sound tags
    content     text        NOT NULL DEFAULT '',
    audio_uk    text        NOT NULL DEFAULT '',
    audio_us    text        NOT NULL DEFAULT '',
    created_at  timestamptz NOT NULL DEFAULT now(),
    exported_at timestamptz,
    PRIMARY KEY (user_id, word)
);

-- ListSavedWords (newest first, keyset on created_at and word), the pending count and the export:
-- pending rows of one user.
CREATE INDEX dictionary_saved_words_pending_idx
    ON dictionary_saved_words (user_id, created_at DESC, word)
    WHERE exported_at IS NULL;

-- The retention cleanup: rows exported before a cutoff.
CREATE INDEX dictionary_saved_words_exported_idx
    ON dictionary_saved_words (exported_at)
    WHERE exported_at IS NOT NULL;
