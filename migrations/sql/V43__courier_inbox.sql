-- The in-app inbox of a user (the bell of the web apps). The text is rendered when the event is accepted, in the
-- language of the user, so the row needs nothing else to be shown. It outlives courier_events (a year, not 90 days),
-- so `event_id` is a plain column, not a foreign key.
CREATE TABLE courier_inbox (
    id          uuid        PRIMARY KEY,
    user_id     text        NOT NULL,
    event_id    uuid,
    event_type  text        NOT NULL,
    title       text        NOT NULL,
    body        text        NOT NULL DEFAULT '',
    link        text        NOT NULL DEFAULT '',
    severity    text        NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    read_at     timestamptz,
    archived_at timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- the list (keyset on created_at, id) and the unread counter of the bell
CREATE INDEX courier_inbox_list_idx ON courier_inbox (user_id, created_at DESC, id DESC) WHERE archived_at IS NULL;
CREATE INDEX courier_inbox_unread_idx ON courier_inbox (user_id) WHERE read_at IS NULL AND archived_at IS NULL;
CREATE INDEX courier_inbox_created_idx ON courier_inbox (created_at);
