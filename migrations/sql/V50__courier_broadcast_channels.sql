-- The channels an announcement was sent on ("email", "in_app", "push"); empty: every channel of the event type
-- (the announcements made before the channels could be chosen).
ALTER TABLE courier_broadcasts ADD COLUMN channels text[] NOT NULL DEFAULT '{}';
