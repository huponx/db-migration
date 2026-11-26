-- Progress inside a part of an export job: the words of the part that is being built that are done, an estimate the
-- worker writes while it downloads the audio and adds the cards. `built` stays the words of the finished parts (it
-- changes only when a part is recorded); the page shows built + building. It is 0 between parts.
-- IF NOT EXISTS: safe to apply by hand first.
ALTER TABLE dictionary_export_jobs ADD COLUMN IF NOT EXISTS building integer NOT NULL DEFAULT 0;
