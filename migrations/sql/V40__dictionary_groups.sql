-- Groups of the dictionary service. A saved word belongs to a group of dictionaries ('en' = english +
-- english-vietnamese, 'vi-ja' = vietnamese-japanese, ...): the dictionaries of one group merge into one card, and
-- the same word in two groups is two cards. The key of a word is (user_id, grp, word).
--
-- Every row that exists gets 'en' through the column default; the default is dropped at the end, so every writer
-- has to pass a group. The settings are JSON and need no migration: the `dictionaries` map replaces the keys
-- english_enabled / english_vi_enabled (dictionary_settings) and englishEnabled / englishViEnabled / the default
-- dictionary of identity_user_settings; the service reads no legacy key (a dictionary missing from the map takes
-- the default of the registry).

-- 1. The column on every table keyed by (user_id, word).
ALTER TABLE dictionary_saved_words   ADD COLUMN grp text NOT NULL DEFAULT 'en';
ALTER TABLE dictionary_image_refs    ADD COLUMN grp text NOT NULL DEFAULT 'en';
ALTER TABLE dictionary_audio_refs    ADD COLUMN grp text NOT NULL DEFAULT 'en';
ALTER TABLE dictionary_review_state  ADD COLUMN grp text NOT NULL DEFAULT 'en';
ALTER TABLE dictionary_review_log    ADD COLUMN grp text NOT NULL DEFAULT 'en';
ALTER TABLE dictionary_word_categories ADD COLUMN grp text NOT NULL DEFAULT 'en';

-- 2. The primary key of the words; CASCADE drops the foreign keys that point at it.
ALTER TABLE dictionary_saved_words DROP CONSTRAINT dictionary_saved_words_pkey CASCADE;
ALTER TABLE dictionary_saved_words ADD PRIMARY KEY (user_id, grp, word);

ALTER TABLE dictionary_image_refs DROP CONSTRAINT dictionary_image_refs_pkey;
ALTER TABLE dictionary_image_refs ADD PRIMARY KEY (user_id, grp, word, image_id);
ALTER TABLE dictionary_image_refs ADD FOREIGN KEY (user_id, grp, word)
    REFERENCES dictionary_saved_words (user_id, grp, word) ON DELETE CASCADE;

ALTER TABLE dictionary_audio_refs DROP CONSTRAINT dictionary_audio_refs_pkey;
ALTER TABLE dictionary_audio_refs ADD PRIMARY KEY (user_id, grp, word, audio_id);
ALTER TABLE dictionary_audio_refs ADD FOREIGN KEY (user_id, grp, word)
    REFERENCES dictionary_saved_words (user_id, grp, word) ON DELETE CASCADE;

ALTER TABLE dictionary_review_state DROP CONSTRAINT dictionary_review_state_pkey;
ALTER TABLE dictionary_review_state ADD PRIMARY KEY (user_id, grp, word);
ALTER TABLE dictionary_review_state ADD FOREIGN KEY (user_id, grp, word)
    REFERENCES dictionary_saved_words (user_id, grp, word) ON DELETE CASCADE;

ALTER TABLE dictionary_review_log DROP CONSTRAINT dictionary_review_log_pkey;
ALTER TABLE dictionary_review_log ADD PRIMARY KEY (user_id, grp, word, reviewed_at);
ALTER TABLE dictionary_review_log ADD FOREIGN KEY (user_id, grp, word)
    REFERENCES dictionary_saved_words (user_id, grp, word) ON DELETE CASCADE;

ALTER TABLE dictionary_word_categories DROP CONSTRAINT dictionary_word_categories_pkey;
ALTER TABLE dictionary_word_categories ADD PRIMARY KEY (user_id, grp, word, category_id);
ALTER TABLE dictionary_word_categories ADD FOREIGN KEY (user_id, grp, word)
    REFERENCES dictionary_saved_words (user_id, grp, word) ON DELETE CASCADE;

-- 3. The indexes of the list keep the user first and the group next, so every query of one group is a range of them.
DROP INDEX dictionary_saved_words_list_idx;
CREATE INDEX dictionary_saved_words_list_idx
    ON dictionary_saved_words (user_id, grp, created_at DESC, word)
    WHERE removed_at IS NULL;

DROP INDEX dictionary_saved_words_new_idx;
CREATE INDEX dictionary_saved_words_new_idx
    ON dictionary_saved_words (user_id, grp, created_at, word)
    WHERE removed_at IS NULL AND NOT review_started;

DROP INDEX dictionary_saved_words_uncategorized_idx;
CREATE INDEX dictionary_saved_words_uncategorized_idx
    ON dictionary_saved_words (user_id, grp, created_at DESC, word DESC)
    WHERE removed_at IS NULL AND NOT categorized;

DROP INDEX dictionary_saved_words_unexported_idx;
CREATE INDEX dictionary_saved_words_unexported_idx
    ON dictionary_saved_words (user_id, grp)
    WHERE removed_at IS NULL AND exported_at IS NULL;

DROP INDEX dictionary_saved_words_exported_idx;
CREATE INDEX dictionary_saved_words_exported_idx
    ON dictionary_saved_words (user_id, grp)
    WHERE removed_at IS NULL AND exported_at IS NOT NULL;

DROP INDEX dictionary_saved_words_new_uncategorized_idx;
CREATE INDEX dictionary_saved_words_new_uncategorized_idx
    ON dictionary_saved_words (user_id, grp)
    WHERE removed_at IS NULL AND exported_at IS NULL AND NOT categorized;

-- the trigram index of the search is on the word alone: the group filter is applied on the rows it finds
-- (dictionary_saved_words_removed_idx, the retention cleanup, has no user and stays)

DROP INDEX dictionary_word_categories_list_idx;
CREATE INDEX dictionary_word_categories_list_idx
    ON dictionary_word_categories (user_id, category_id, grp, created_at DESC, word DESC);

DROP INDEX dictionary_review_state_due_idx;
CREATE INDEX dictionary_review_state_due_idx ON dictionary_review_state (user_id, grp, due_at) INCLUDE (learning);

DROP INDEX dictionary_review_state_last_idx;
CREATE INDEX dictionary_review_state_last_idx
    ON dictionary_review_state (user_id, grp, last_reviewed_at) INCLUDE (first_reviewed_at);

-- 4. Every writer passes a group from now on.
ALTER TABLE dictionary_saved_words     ALTER COLUMN grp DROP DEFAULT;
ALTER TABLE dictionary_image_refs      ALTER COLUMN grp DROP DEFAULT;
ALTER TABLE dictionary_audio_refs      ALTER COLUMN grp DROP DEFAULT;
ALTER TABLE dictionary_review_state    ALTER COLUMN grp DROP DEFAULT;
ALTER TABLE dictionary_review_log      ALTER COLUMN grp DROP DEFAULT;
ALTER TABLE dictionary_word_categories ALTER COLUMN grp DROP DEFAULT;

-- The export jobs keep the group in their params (jsonb): no column.
