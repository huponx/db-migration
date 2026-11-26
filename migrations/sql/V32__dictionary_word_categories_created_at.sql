-- A page of the words of one category, newest first, as an index scan on the links.
-- The links carry the created_at of their word (the service keeps them equal: a word saved again gets a new
-- created_at on its row and on its links, a link added copies it). Without it a category whose words are all old
-- made the page walk the newest words of the whole list, testing every one for a link (450 ms at 1,000,000 words).
-- IF NOT EXISTS: safe to apply by hand first.
ALTER TABLE dictionary_word_categories ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

UPDATE dictionary_word_categories wc SET created_at = w.created_at
FROM dictionary_saved_words w
WHERE w.user_id = wc.user_id AND w.word = wc.word AND wc.created_at <> w.created_at;

CREATE INDEX IF NOT EXISTS dictionary_word_categories_list_idx
    ON dictionary_word_categories (user_id, category_id, created_at DESC, word DESC);

-- (user_id, category_id) is the prefix of the new index
DROP INDEX IF EXISTS dictionary_word_categories_category_idx;
