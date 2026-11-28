-- Digest: events of the same kind that come close together reach a person as ONE message ("3 registrations are
-- waiting"), not as one each.
--
-- The first delivery of a group is the leader: it is created `pending` with its first attempt at the end of the window
-- and carries a `digest_key` (event type plus the values the type groups by). A later event with the same key for the
-- same channel and address does not create a delivery: it is attached to the leader (courier_digest_items) and goes out
-- with it. When a worker claims the leader it clears the key (the group is closed: the next event starts a new one) and
-- sends the leader and its items as one message.
ALTER TABLE courier_deliveries ADD COLUMN digest_key text NOT NULL DEFAULT '';

-- one open group per key and address: two concurrent events cannot both become the leader
CREATE UNIQUE INDEX courier_deliveries_digest_open_idx ON courier_deliveries (digest_key, channel, address)
    WHERE digest_key <> '' AND status = 'pending';

CREATE TABLE courier_digest_items (
    delivery_id uuid        NOT NULL REFERENCES courier_deliveries (id) ON DELETE CASCADE,
    event_id    uuid        NOT NULL REFERENCES courier_events (id) ON DELETE CASCADE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (delivery_id, event_id)
);
CREATE INDEX courier_digest_items_event_idx ON courier_digest_items (event_id);
