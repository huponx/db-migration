-- Web Push: the subscription of a browser (one per device), by the endpoint of its push service. A delivery to a
-- subscription is a row of courier_deliveries with channel 'push' and the id of the subscription as address; when the
-- push service says the subscription is gone (404, 410) courier deletes it.
CREATE TABLE courier_push_subscriptions (
    id         uuid        PRIMARY KEY,
    user_id    text        NOT NULL,
    endpoint   text        NOT NULL UNIQUE,
    p256dh     text        NOT NULL,
    auth       text        NOT NULL,
    user_agent text        NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX courier_push_subscriptions_user_idx ON courier_push_subscriptions (user_id, created_at);

ALTER TABLE courier_deliveries DROP CONSTRAINT courier_deliveries_channel_check;
ALTER TABLE courier_deliveries ADD CONSTRAINT courier_deliveries_channel_check
    CHECK (channel IN ('email', 'telegram', 'webhook', 'push'));

ALTER TABLE courier_user_prefs DROP CONSTRAINT courier_user_prefs_channel_check;
ALTER TABLE courier_user_prefs ADD CONSTRAINT courier_user_prefs_channel_check
    CHECK (channel IN ('email', 'telegram', 'in_app', 'push'));
