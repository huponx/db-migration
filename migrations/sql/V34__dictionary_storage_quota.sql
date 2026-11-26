-- Storage quotas of the dictionary service.
--   content_bytes  total size of the content of the words in the list (octet_length(content) of the rows of
--                  dictionary_saved_words with removed_at IS NULL), kept like listed, in the transaction of the change
--   content_quota, image_quota, audio_quota
--                  limits of one user that replace the ones of the system settings; NULL: the setting applies
ALTER TABLE dictionary_user_stats
    ADD COLUMN content_bytes bigint NOT NULL DEFAULT 0 CHECK (content_bytes >= 0),
    ADD COLUMN content_quota bigint CHECK (content_quota IS NULL OR content_quota > 0),
    ADD COLUMN image_quota   bigint CHECK (image_quota IS NULL OR image_quota > 0),
    ADD COLUMN audio_quota   bigint CHECK (audio_quota IS NULL OR audio_quota > 0);

INSERT INTO dictionary_user_stats (user_id, content_bytes)
SELECT user_id, sum(octet_length(content)) FROM dictionary_saved_words WHERE removed_at IS NULL GROUP BY user_id
ON CONFLICT (user_id) DO UPDATE SET content_bytes = EXCLUDED.content_bytes;
