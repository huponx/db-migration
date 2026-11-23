-- Profile picture of a user: the encoded image (resized by the admin UI, validated by identity)
-- and its media type. Both NULL when the user has no picture.
ALTER TABLE identity_users
    ADD COLUMN avatar      bytea,
    ADD COLUMN avatar_mime text,
    ADD CONSTRAINT identity_users_avatar_pair CHECK ((avatar IS NULL) = (avatar_mime IS NULL)),
    ADD CONSTRAINT identity_users_avatar_size CHECK (avatar IS NULL OR octet_length(avatar) <= 65536);
