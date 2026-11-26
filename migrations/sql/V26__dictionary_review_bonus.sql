-- Extra daily review allowance a user asked for ("study more today", dictionary service). It adds to the two
-- limits of the user settings (new words and review cards per 24 hours) until expires_at and is not part of those
-- settings. The row belongs to the user alone, not to a word, so it has no foreign key like V24 has.
CREATE TABLE dictionary_review_bonus (
    user_id       uuid        PRIMARY KEY,
    -- new words and review cards on top of the daily limits
    extra_new     integer     NOT NULL DEFAULT 0,
    extra_reviews integer     NOT NULL DEFAULT 0,
    -- 24 hours after the last grant; an expired row counts as no bonus
    expires_at    timestamptz NOT NULL
);
