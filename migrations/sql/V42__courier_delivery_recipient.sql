-- A notification to several users has one event but a different name and locale per recipient: the
-- per-recipient part moves to the delivery. `user_id` is the audit link to identity (empty for a raw address),
-- `locale` overrides the locale of the event when set, `vars` is merged over the event data when rendering.
ALTER TABLE courier_deliveries
    ADD COLUMN user_id text  NOT NULL DEFAULT '',
    ADD COLUMN locale  text  NOT NULL DEFAULT '',
    ADD COLUMN vars    jsonb NOT NULL DEFAULT '{}',
    ADD CONSTRAINT courier_deliveries_vars_object CHECK (jsonb_typeof(vars) = 'object');

CREATE INDEX courier_deliveries_user_idx ON courier_deliveries (user_id, created_at DESC) WHERE user_id <> '';
