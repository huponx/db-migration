-- Per-user counters of the dictionary service, so that saving a word and checking the limits never count the rows
-- of a list that can hold 1,000,000 words.
--   listed       words in the list (dictionary_saved_words with removed_at IS NULL)
--   image_bytes  total size of the images of the user (dictionary_images.size)
--   audio_bytes  total size of the audio files of the user (dictionary_audio.size)
-- The service updates a counter in the same transaction as the change it counts; a daily job recomputes
-- listed for a batch of users and logs a mismatch.
CREATE TABLE dictionary_user_stats (
    user_id     uuid   PRIMARY KEY REFERENCES identity_users (id) ON DELETE CASCADE,
    listed      bigint NOT NULL DEFAULT 0 CHECK (listed >= 0),
    image_bytes bigint NOT NULL DEFAULT 0 CHECK (image_bytes >= 0),
    audio_bytes bigint NOT NULL DEFAULT 0 CHECK (audio_bytes >= 0)
);

INSERT INTO dictionary_user_stats (user_id, listed)
SELECT user_id, count(*) FROM dictionary_saved_words WHERE removed_at IS NULL GROUP BY user_id;

INSERT INTO dictionary_user_stats (user_id, image_bytes)
SELECT user_id, sum(size) FROM dictionary_images GROUP BY user_id
ON CONFLICT (user_id) DO UPDATE SET image_bytes = EXCLUDED.image_bytes;

INSERT INTO dictionary_user_stats (user_id, audio_bytes)
SELECT user_id, sum(size) FROM dictionary_audio GROUP BY user_id
ON CONFLICT (user_id) DO UPDATE SET audio_bytes = EXCLUDED.audio_bytes;
