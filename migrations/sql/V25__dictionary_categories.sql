-- Categories of the saved words (dictionary service): a user groups words in categories, a word may be in several
-- (like tags). The links belong to (user_id, word) like the images, audio refs and review state of V21/V23/V24:
-- editing the card keeps them, deleting the word takes them along; deleting a category only removes the links.
CREATE TABLE dictionary_categories (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
    name       text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX dictionary_categories_name_idx ON dictionary_categories (user_id, lower(name));

CREATE TABLE dictionary_word_categories (
    user_id     uuid NOT NULL,
    word        text NOT NULL,
    category_id uuid NOT NULL REFERENCES dictionary_categories (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, word, category_id),
    FOREIGN KEY (user_id, word) REFERENCES dictionary_saved_words (user_id, word) ON DELETE CASCADE
);

CREATE INDEX dictionary_word_categories_category_idx ON dictionary_word_categories (user_id, category_id);
