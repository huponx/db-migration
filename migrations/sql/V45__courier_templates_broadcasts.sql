-- Templates edited in the admin app. The templates built into courier stay the fallback: a row here wins for its
-- (template, locale, channel), deleting the row (revert) brings the built-in one back.
--
-- `files` maps the file of the template directory to its text:
--   email    {"email.subject.tmpl", "email.txt.tmpl", "email.html.tmpl"}
--   telegram {"telegram.txt.tmpl"}
--   in_app   {"in_app.title.tmpl", "in_app.body.tmpl"}
CREATE TABLE courier_templates (
    template   text        NOT NULL,
    locale     text        NOT NULL,
    channel    text        NOT NULL CHECK (channel IN ('email', 'telegram', 'in_app')),
    version    integer     NOT NULL,
    files      jsonb       NOT NULL,
    updated_by text        NOT NULL DEFAULT '',
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (template, locale, channel),
    CONSTRAINT courier_templates_files_object CHECK (jsonb_typeof(files) = 'object')
);

-- Every save and every revert, newest version last. `files` is NULL for a revert.
CREATE TABLE courier_template_versions (
    template   text        NOT NULL,
    locale     text        NOT NULL,
    channel    text        NOT NULL CHECK (channel IN ('email', 'telegram', 'in_app')),
    version    integer     NOT NULL,
    files      jsonb,
    updated_by text        NOT NULL DEFAULT '',
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (template, locale, channel, version)
);

-- Announcements of the administrators.
CREATE TABLE courier_broadcasts (
    id         uuid        PRIMARY KEY,
    event_type text        NOT NULL,
    audience   jsonb       NOT NULL,
    data       jsonb       NOT NULL DEFAULT '{}',
    created_by text        NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    recipients integer     NOT NULL DEFAULT 0,
    skipped    integer     NOT NULL DEFAULT 0
);
CREATE INDEX courier_broadcasts_created_idx ON courier_broadcasts (created_at DESC, id DESC);

-- The delivery log filters by status, user and notification.
CREATE INDEX courier_deliveries_log_idx ON courier_deliveries (created_at DESC, id DESC);
CREATE INDEX courier_deliveries_status_idx ON courier_deliveries (status, created_at DESC);

-- The permissions of these screens (courier/v1/permissions.proto) are not inserted here: courier registers them with
-- identity at start (RegisterPermissions), see the README of courier.
