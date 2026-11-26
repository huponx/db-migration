-- Spaced repetition state of the saved words (dictionary service, SM-2 with four grades). A word with no row
-- is new. The row belongs to (user_id, word) like the images and audio refs of V21/V23: editing the card keeps
-- it, deleting the word (by hand or by the cleanup) takes it along.
CREATE TABLE dictionary_review_state (
    user_id           uuid        NOT NULL,
    word              text        NOT NULL,
    ease              real        NOT NULL DEFAULT 2.5,
    interval_days     integer     NOT NULL DEFAULT 0,
    reps              integer     NOT NULL DEFAULT 0,
    lapses            integer     NOT NULL DEFAULT 0,
    -- true: the word is being (re)learned, interval_days is 0 and due_at is minutes away
    learning          boolean     NOT NULL DEFAULT true,
    due_at            timestamptz NOT NULL,
    first_reviewed_at timestamptz NOT NULL,
    last_reviewed_at  timestamptz NOT NULL,
    PRIMARY KEY (user_id, word),
    FOREIGN KEY (user_id, word) REFERENCES dictionary_saved_words (user_id, word) ON DELETE CASCADE
);

CREATE INDEX dictionary_review_state_due_idx ON dictionary_review_state (user_id, due_at);
CREATE INDEX dictionary_review_state_first_idx ON dictionary_review_state (user_id, first_reviewed_at);
