-- "Uncategorized" and "new words" lists for lists of 1,000,000 words.
-- 1. categorized: the word has at least one category link. NOT EXISTS on the links cannot stop early when most
--    words are categorized; a flag with a partial index can. The service keeps it in step with the links.
ALTER TABLE dictionary_saved_words ADD COLUMN categorized boolean NOT NULL DEFAULT false;

UPDATE dictionary_saved_words w SET categorized = true
WHERE EXISTS (SELECT 1 FROM dictionary_word_categories wc WHERE wc.user_id = w.user_id AND wc.word = w.word);

-- the Uncategorized page, newest first (the order of ListSavedWords)
CREATE INDEX dictionary_saved_words_uncategorized_idx
    ON dictionary_saved_words (user_id, created_at DESC, word DESC)
    WHERE removed_at IS NULL AND NOT categorized;

-- the capped count of new (never exported) words
CREATE INDEX dictionary_saved_words_unexported_idx
    ON dictionary_saved_words (user_id)
    WHERE removed_at IS NULL AND exported_at IS NULL;
