-- A saved word that was exported can stay in the list of the user (the setting "remove saved words after
-- export" is off), so "exported" and "left the list" are two things now:
--   exported_at: the word was packed in a deck (NULL = new, the next "export new" packs it)
--   removed_at:  the word left the list; the retention cleanup deletes it some time later (NULL = in the list)
ALTER TABLE dictionary_saved_words ADD COLUMN removed_at timestamptz;

-- Everything exported so far left the list.
UPDATE dictionary_saved_words SET removed_at = exported_at WHERE exported_at IS NOT NULL;

-- ListSavedWords (newest first, keyset on created_at and word), the count and the export: the rows of one user
-- that are in the list.
DROP INDEX dictionary_saved_words_pending_idx;
CREATE INDEX dictionary_saved_words_list_idx
    ON dictionary_saved_words (user_id, created_at DESC, word)
    WHERE removed_at IS NULL;

-- The retention cleanup: rows that left the list before a cutoff.
DROP INDEX dictionary_saved_words_exported_idx;
CREATE INDEX dictionary_saved_words_removed_idx
    ON dictionary_saved_words (removed_at)
    WHERE removed_at IS NOT NULL;
