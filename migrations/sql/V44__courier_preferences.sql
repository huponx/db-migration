-- What a user chose about notifications, and where courier reaches them.
--
-- courier_user_prefs: a row only for a choice that differs from the default (every channel on). A mandatory
-- category (security) ignores it.
CREATE TABLE courier_user_prefs (
    user_id    text        NOT NULL,
    category   text        NOT NULL,
    channel    text        NOT NULL CHECK (channel IN ('email', 'telegram', 'in_app')),
    enabled    boolean     NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, category, channel)
);

-- Quiet hours: a non-mandatory e-mail or Telegram message that arrives inside the window waits for its end.
-- from_min / to_min are minutes after midnight in `tz`; the window may cross midnight.
CREATE TABLE courier_user_quiet_hours (
    user_id    text        PRIMARY KEY,
    tz         text        NOT NULL,
    from_min   integer     NOT NULL CHECK (from_min BETWEEN 0 AND 1439),
    to_min     integer     NOT NULL CHECK (to_min BETWEEN 0 AND 1439),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT courier_quiet_window CHECK (from_min <> to_min)
);

-- The address of a user on a channel that identity does not know (the Telegram chat). E-mail comes from identity.
CREATE TABLE courier_channel_bindings (
    user_id     text        NOT NULL,
    channel     text        NOT NULL CHECK (channel IN ('telegram')),
    address     text        NOT NULL,
    verified_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, channel)
);

-- One-time codes the user sends to the bot (`/start <code>`) to prove the chat is theirs.
CREATE TABLE courier_binding_codes (
    code       text        PRIMARY KEY,
    user_id    text        NOT NULL,
    channel    text        NOT NULL CHECK (channel IN ('telegram')),
    expires_at timestamptz NOT NULL
);
CREATE INDEX courier_binding_codes_user_idx ON courier_binding_codes (user_id);

-- A delivery the user's choice turned off is kept as an audit row, not sent.
ALTER TABLE courier_deliveries DROP CONSTRAINT courier_deliveries_status_check;
ALTER TABLE courier_deliveries ADD CONSTRAINT courier_deliveries_status_check
    CHECK (status IN ('pending', 'sent', 'failed', 'dead', 'skipped'));
