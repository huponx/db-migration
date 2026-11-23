-- When the user last completed a sign in (password, and the second factor when there is one).
-- NULL until the first sign in after this migration; users who signed in before it show "never".
ALTER TABLE identity_users
    ADD COLUMN last_login_at timestamptz;
