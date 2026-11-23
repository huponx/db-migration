-- Permissions of the dictionary service, checked by its gRPC methods (dictionary/internal/service
-- Permissions). Like the identity ones they are part of the catalog roles can be given; an admin
-- holding "*" has them already.
INSERT INTO identity_permissions (permission, description) VALUES
    ('dictionary:word:read', 'Look words up and list the saved words'),
    ('dictionary:word:write', 'Save and delete words, export them as an Anki deck')
ON CONFLICT DO NOTHING;
