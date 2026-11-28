-- Courier keeps its state in PostgreSQL (source of truth); Redis Streams is only the work queue.
--
-- courier_events: one row per accepted SendNotification. `idempotency_key` replaces the 24 hour key in Redis.
-- `data` holds the template data for the retries; it is emptied when every delivery of the event is sent
-- (a reset link or a recovery code must not stay in the database).
CREATE TABLE courier_events (
    id              uuid        PRIMARY KEY,
    idempotency_key text        UNIQUE,
    event_type      text        NOT NULL,
    locale          text        NOT NULL,
    data            jsonb       NOT NULL DEFAULT '{}',
    correlation_id  text        NOT NULL DEFAULT '',
    request_id      text        NOT NULL DEFAULT '',
    user_id         text        NOT NULL DEFAULT '',
    tenant_id       text        NOT NULL DEFAULT '',
    agency_id       text        NOT NULL DEFAULT '',
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT courier_events_data_object CHECK (jsonb_typeof(data) = 'object')
);

CREATE INDEX courier_events_created_idx ON courier_events (created_at);

-- courier_deliveries: one row per (event x channel x address); the audit trail and the retry state.
--   pending: waiting for the first send or the next retry (next_attempt_at)
--   sent / failed (permanent error, not retried) / dead (out of attempts, the dead-letter state)
-- `enqueued_at` is the outbox: a pending row without it (or with an old one) is pushed to Redis by the relay.
-- `locked_until` is the lease of the worker that is sending it right now.
CREATE TABLE courier_deliveries (
    id              uuid        PRIMARY KEY,
    event_id        uuid        NOT NULL REFERENCES courier_events (id) ON DELETE CASCADE,
    channel         text        NOT NULL CHECK (channel IN ('email', 'telegram')),
    address         text        NOT NULL,
    status          text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'dead')),
    attempts        integer     NOT NULL DEFAULT 0,
    last_error      text        NOT NULL DEFAULT '',
    next_attempt_at timestamptz NOT NULL DEFAULT now(),
    enqueued_at     timestamptz,
    locked_until    timestamptz,
    sent_at         timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX courier_deliveries_event_idx ON courier_deliveries (event_id);
-- the relay scans only the open work
CREATE INDEX courier_deliveries_due_idx ON courier_deliveries (next_attempt_at) WHERE status = 'pending';
CREATE INDEX courier_deliveries_dead_idx ON courier_deliveries (updated_at) WHERE status IN ('failed', 'dead');
