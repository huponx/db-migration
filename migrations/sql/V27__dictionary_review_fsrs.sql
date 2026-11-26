-- FSRS option of the review (dictionary service) and the indexes the review needs for lists of 1,000,000 words.

-- 1. FSRS memory of a card. 0 = none yet (a card learned with SM-2 gets it on its first FSRS grade). Both
-- algorithms write the SM-2 columns, so switching back and forth keeps the history.
ALTER TABLE dictionary_review_state
    ADD COLUMN stability  real NOT NULL DEFAULT 0,
    ADD COLUMN difficulty real NOT NULL DEFAULT 0;

-- 2. One row per grade: the input of the parameter optimizer. The log belongs to the word like the review state.
CREATE TABLE dictionary_review_log (
    user_id         uuid        NOT NULL,
    word            text        NOT NULL,
    reviewed_at     timestamptz NOT NULL,
    grade           smallint    NOT NULL,
    -- seconds since the previous grade of the card; 0 for the first one
    elapsed_seconds bigint      NOT NULL DEFAULT 0,
    -- the card was being learned before this grade
    was_learning    boolean     NOT NULL DEFAULT false,
    PRIMARY KEY (user_id, word, reviewed_at),
    FOREIGN KEY (user_id, word) REFERENCES dictionary_saved_words (user_id, word) ON DELETE CASCADE
);
CREATE INDEX dictionary_review_log_user_idx ON dictionary_review_log (user_id, reviewed_at);
-- append-only in time: the cheapest index for the cleanup of old rows
CREATE INDEX dictionary_review_log_time_idx ON dictionary_review_log USING brin (reviewed_at);

-- 3. FSRS weights of a user. weights NULL: optimized, but the default weights stay (nothing better was found).
-- attempted_at is the rate limit between replicas. The row goes with the user.
CREATE TABLE dictionary_fsrs_params (
    user_id      uuid        PRIMARY KEY REFERENCES identity_users (id) ON DELETE CASCADE,
    weights      real[],
    review_count integer     NOT NULL DEFAULT 0,
    loss_default real,
    loss_trained real,
    trained_at   timestamptz,
    attempted_at timestamptz NOT NULL
);

-- 4. Review paths that do not depend on the number of words of the user.
-- review_started: the word has a review state, so "new words" is an index scan and not an anti-join.
ALTER TABLE dictionary_saved_words ADD COLUMN review_started boolean NOT NULL DEFAULT false;
UPDATE dictionary_saved_words w SET review_started = true
    FROM dictionary_review_state r WHERE r.user_id = w.user_id AND r.word = w.word;

-- new cards in the order of the review (created_at, word)
CREATE INDEX dictionary_saved_words_new_idx
    ON dictionary_saved_words (user_id, created_at, word)
    WHERE removed_at IS NULL AND NOT review_started;

-- due and learning cards, and the count of each, from the index alone
DROP INDEX dictionary_review_state_due_idx;
CREATE INDEX dictionary_review_state_due_idx ON dictionary_review_state (user_id, due_at) INCLUDE (learning);

-- first and last review of the cards reviewed in the last 24 hours
DROP INDEX dictionary_review_state_first_idx;
CREATE INDEX dictionary_review_state_last_idx
    ON dictionary_review_state (user_id, last_reviewed_at) INCLUDE (first_reviewed_at);
