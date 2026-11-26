-- Soft delete of an account. DeleteUser (identity) sets deleted_at, disables the user and anonymizes email and name;
-- the heavy data of the user (dictionary words, images, audio, exports) is deleted in batches by the cleanup of
-- dictionary-worker, which then sets purged_at, and the row itself is deleted after DICTIONARY_PURGE_GRACE.
-- Nothing may DELETE FROM identity_users directly: the ON DELETE CASCADE of the tables of a user with 1,000,000
-- words runs in one statement (see the README).
--   deleted_at  when the account was deleted (NULL: a live account)
--   purged_at   when the data of the services was found deleted (NULL: the purge is not done); the cleanup clears
--               it again when it finds rows written after that
ALTER TABLE identity_users
    ADD COLUMN deleted_at timestamptz,
    ADD COLUMN purged_at  timestamptz;

-- The purge takes the oldest deleted users first; the index holds only them.
CREATE INDEX identity_users_deleted_idx ON identity_users (deleted_at) WHERE deleted_at IS NOT NULL;
