-- Webhooks: endpoints (a Slack channel, or any service) that receive the events they subscribe to, once per event.
-- The delivery of an event to a webhook is a row of courier_deliveries with channel 'webhook' and the id of the
-- webhook as its address, so it has the same retries, dead letters, log and metrics as an e-mail.
CREATE TABLE courier_webhooks (
    id         uuid        PRIMARY KEY,
    name       text        NOT NULL,
    url        text        NOT NULL,
    kind       text        NOT NULL CHECK (kind IN ('slack', 'generic')),
    -- exact types, prefixes ("bvchain.*") or "*"
    events     text[]      NOT NULL DEFAULT '{}',
    enabled    boolean     NOT NULL DEFAULT true,
    -- the HMAC key of a generic webhook; never sent back by the API
    secret     text        NOT NULL DEFAULT '',
    created_by text        NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE courier_deliveries DROP CONSTRAINT courier_deliveries_channel_check;
ALTER TABLE courier_deliveries ADD CONSTRAINT courier_deliveries_channel_check
    CHECK (channel IN ('email', 'telegram', 'webhook'));
