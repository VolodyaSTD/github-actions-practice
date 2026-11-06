CREATE TABLE IF NOT EXISTS items (
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(100)   NOT NULL,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0
);

INSERT INTO items (name, price) VALUES
    ('Ноутбук', 75000.00),
    ('Монитор', 18990.50),
    ('Клавиатура', 3490.00),
    ('Мышь', 1290.00),
    ('Наушники', 5990.00);
