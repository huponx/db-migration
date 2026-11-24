-- Search of the saved words (ListSavedWords query): word ILIKE '%text%' for one user. A trigram index makes
-- the substring match (case-insensitive) cheap for big lists. pg_trgm is a trusted extension (PostgreSQL 13+).
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX dictionary_saved_words_word_trgm_idx
    ON dictionary_saved_words USING gin (word gin_trgm_ops)
    WHERE removed_at IS NULL;
