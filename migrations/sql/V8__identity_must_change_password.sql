-- A user created with a password somebody else knows (the setup Job of identity) must choose
-- their own at the first sign in. identity clears the flag when the user sets a password.
ALTER TABLE identity_users ADD COLUMN must_change_password boolean NOT NULL DEFAULT false;
