-- Asynchronous export of a long list (dictionary service). A synchronous export packs at most a few thousand
-- words in one deck; a job packs the whole list in parts, each part a deck file of at most the size limit.
--   status      queued | running | done | failed | cancelled
--   params      what to export and how, fixed when the job starts: scope, categoryId, uncategorized, deckName,
--               fresh, remove, and the keyset (afterCreated, afterWord) of the last word packed, so a job taken
--               over by another replica goes on after it
--   lease_id    changes every time a replica takes the job; every write of the worker checks it, so a replica
--               that lost the lease cannot write
--   lease_until the lease ends here; a running job whose lease ended is taken again
CREATE TABLE dictionary_export_jobs (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    status      text        NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'done', 'failed', 'cancelled')),
    params      jsonb       NOT NULL,
    total       integer     NOT NULL DEFAULT 0,
    built       integer     NOT NULL DEFAULT 0,
    parts       integer     NOT NULL DEFAULT 0,
    error       text        NOT NULL DEFAULT '',
    lease_id    uuid,
    lease_until timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    expires_at  timestamptz NOT NULL
);

-- one job at a time per user
CREATE UNIQUE INDEX dictionary_export_jobs_active_idx ON dictionary_export_jobs (user_id) WHERE status IN ('queued', 'running');
-- the job of the user that was started last
CREATE INDEX dictionary_export_jobs_user_idx ON dictionary_export_jobs (user_id, created_at DESC);
-- taking a job: the queued ones, and the running ones whose lease ended
CREATE INDEX dictionary_export_jobs_todo_idx ON dictionary_export_jobs (created_at) WHERE status IN ('queued', 'running');
-- the cleanup of expired jobs
CREATE INDEX dictionary_export_jobs_expires_idx ON dictionary_export_jobs (expires_at);

-- The files of a job: the deck file is <file_id>.apkg in the export directory of the user. token_hash is the
-- SHA-256 of the token of the download link of the part (NULL until a link is made); unlike the link of a deck it
-- works until the job expires, because a user downloads many parts.
CREATE TABLE dictionary_export_parts (
    job_id     uuid    NOT NULL REFERENCES dictionary_export_jobs (id) ON DELETE CASCADE,
    n          integer NOT NULL,
    filename   text    NOT NULL,
    file_id    uuid    NOT NULL,
    word_count integer NOT NULL,
    size       integer NOT NULL,
    token_hash bytea,
    PRIMARY KEY (job_id, n)
);
CREATE UNIQUE INDEX dictionary_export_parts_token_idx ON dictionary_export_parts (token_hash) WHERE token_hash IS NOT NULL;
