-- Indexes the performance measurements of 1,000,000 words asked for (dictionary/docs/performance).
-- IF NOT EXISTS: safe to apply by hand first.

-- RemoveExported takes the words that were exported and are still in the list out of it in batches; without this it
-- read the whole list (a Seq Scan of every word of every user) for every batch.
CREATE INDEX IF NOT EXISTS dictionary_saved_words_exported_idx
    ON dictionary_saved_words (user_id)
    WHERE removed_at IS NULL AND exported_at IS NOT NULL;

-- The capped count of the new words of the Uncategorized filter stops at 10,000 rows only if it can walk new words
-- that are in no category without skipping the others.
CREATE INDEX IF NOT EXISTS dictionary_saved_words_new_uncategorized_idx
    ON dictionary_saved_words (user_id)
    WHERE removed_at IS NULL AND exported_at IS NULL AND NOT categorized;
