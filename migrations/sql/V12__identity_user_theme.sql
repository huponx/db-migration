-- The theme the user chose (light, dark or system), shared by every web app. NULL until the user chooses: the apps
-- then follow the system.
ALTER TABLE identity_users
    ADD COLUMN theme text CHECK (theme IN ('light', 'dark', 'system'));
