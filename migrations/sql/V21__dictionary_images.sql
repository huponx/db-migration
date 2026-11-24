-- Images of the cards (dictionary service). The bytes are files on a volume (<dir>/<user_id>/<id>.<ext>); the
-- card content refers to an image as dictimg:<id>. A row is made when an image is uploaded.
CREATE TABLE dictionary_images (
    id           uuid        PRIMARY KEY,
    user_id      uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    content_type text        NOT NULL,
    -- bytes of the file (the quota of a user is the sum)
    size         integer     NOT NULL,
    -- of the normalized file: the same image of one user is stored once
    sha256       bytea       NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, sha256)
);

-- The quota check (sum of size) and the lookup of the images of one user.
CREATE INDEX dictionary_images_user_idx ON dictionary_images (user_id);

-- The garbage collection: images older than a cutoff.
CREATE INDEX dictionary_images_created_idx ON dictionary_images (created_at);

-- Which image a saved word uses. SaveWord rewrites the set of the word in the transaction of the save, so the
-- cleanup finds the unused images without reading any content. A word deleted for good takes its references
-- with it.
CREATE TABLE dictionary_image_refs (
    user_id  uuid NOT NULL,
    word     text NOT NULL,
    image_id uuid NOT NULL REFERENCES dictionary_images (id),
    PRIMARY KEY (user_id, word, image_id),
    FOREIGN KEY (user_id, word) REFERENCES dictionary_saved_words (user_id, word) ON DELETE CASCADE
);

CREATE INDEX dictionary_image_refs_image_idx ON dictionary_image_refs (image_id);
