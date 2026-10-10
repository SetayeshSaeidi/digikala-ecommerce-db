-- 1) Users
INSERT INTO "users" (
  id, email, password_hash, first_name, last_name, phone,
  is_premium, premium_started_at, premium_expires_at
) VALUES
  (1, 'alice@example.com', 'hash_alice',  'Alice', 'Anderson', '+41 44 668 1800', true,  '2025-01-01 10:00:00', '2025-12-31 23:59:59'),
  (2, 'bob@example.com',   'hash_bob',    'Bob',   'Brown',    '044-668-18-00',        false, NULL,                 NULL),
  (3, 'carol@example.com', 'hash_carol',  'Carol', NULL,        NULL,                    false, NULL,                 NULL),
  (4, 'dave@example.com',  'hash_dave',   'Dave',  'Davids',   '+41 786 123 456',      true,  '2024-06-15 08:30:00', '2025-06-14 23:59:59'),
  (5, 'eve@example.com',   'hash_eve',    NULL,    'Evans',    '0041 22 555 1234',     false, NULL,                 NULL),
  (6, 'frank@example.com', 'hash_frank',  'Frank', 'Foster',   NULL,                    false, NULL,                 NULL);

-- 2) Addresses
INSERT INTO "addresses" (
  id, user_id, recipient, street, city, state, postal_code, country, phone, is_default
) VALUES
  (1, 1, 'Alice A.',    'Bahnhofstrasse 1',   'Zurich', 'ZH', '8001', 'Switzerland', '+41 44 668 1800', true),
  (2, 1, 'Alice Work',  'Technoparkstrasse 5','Zurich', 'ZH', '8005', 'Switzerland', NULL,               false),
  (3, 2, 'Bob B.',      'Musterweg 10',        'Bern',   'BE', '3000', 'Switzerland', '031 123 45 67',   true),
  (4, 4, 'Dave Home',   'Seestrasse 100',      'Zurich', 'ZH', '8032', 'Switzerland', '044 123 45 67',   true),
  (5, 4, 'Dave Office', 'Kreuzstrasse 20',     'Winterthur','ZH','8400','Switzerland','052 222 33 44',   true),
  (6, 5, 'Eve E.',      'Rue de la Gare 2',    'Geneva', 'GE', '1201', 'Switzerland', '022 987 65 43',   false),
  (7, 6, 'Frank F.',    'Gotthardstrasse 3',   'Lugano', 'TI', '6900', 'Switzerland', NULL,               true);

-- 3) Categories
INSERT INTO "categories" (
  id, name, parent_id
) VALUES
  (1, 'Electronics',     NULL),
  (2, 'Smartphones',     1),
  (3, 'Accessories',     1),
  (4, 'Chargers',        3),
  (5, 'Cables',          3),
  (6, 'USB-C Cables',    5),
  (7, 'Clothing',        NULL),
  (8, 'Men’s Clothing',  7),
  (9, 'Women’s Clothing',7);

-- 4) Products
INSERT INTO "products" (
  id, title, description, price, upload_date, rating_avg
) VALUES
  (1,  'iPhone 14',              'Latest Apple smartphone',       799.00,     '2025-03-01', 4.50),
  (2,  'Galaxy S21',             'Samsung flagship',              699.00,     '2025-02-15', 4.20),
  (3,  '18W Charger',            'Fast charger',                  19.99,      '2025-01-10', NULL),
  (4,  'USB-C Cable',            'Durable nylon braided cable',   9.99,       '2025-01-05', 4.80),
  (5,  'Basic T-Shirt',          '100% cotton',                   25.00,      '2025-04-10', 3.75),
  (6,  'Free Sticker',           'Promotional sticker',           0.00,       '2025-04-01', NULL),
  (7,  'Luxury Watch',           'Swiss automatic watch',         9999999.99, '2025-05-20', 4.95),
  (8,  'Special Edge & Co. 😃',  'Contains "quotes" & emoji',     49.99,      '2025-06-01', 5.00),
  (9,  'Budget Earbuds',         NULL,                            5.00,       '2025-02-20', 2.00),
  (10, 'VeryExpensiveProduct',   'Test high-price boundary',     10000000.00,'2025-07-01', NULL);

-- 5) Product ⇆ Category
INSERT INTO "product_categories" (product_id, category_id) VALUES
  (1,2), (2,2), (3,4), (4,6),
  (5,7), (5,8), (5,9),
  (6,3), (7,1), (8,3),
  (9,3), (10,1);

-- 6) Product Attributes
INSERT INTO "product_attributes" (
  id, name, data_type, unit
) VALUES
  (1, 'Color',         'text',    NULL),
  (2, 'Weight',        'numeric', 'kg'),
  (3, 'Size',          'text',    NULL),
  (4, 'ReleaseDate',   'date',    NULL),
  (5, 'IsRefurbished', 'boolean', NULL);

-- 7) Attribute Values
INSERT INTO "product_attribute_values" (
  product_id, attribute_id, value_text
) VALUES
  (1,1,'Space Gray'),   (1,2,'0.174'), (1,4,'2025-03-01'),
  (2,1,'Phantom Black'),(2,2,'0.169'),(2,4,'2025-02-15'),
  (3,2,'0.100'),       (3,5,'false'),
  (4,2,'0.050'),       (4,5,'false'),
  (5,3,'L'),           (5,5,'false'),
  (6,1,'StickerWhite'),(6,5,'false'),
  (7,2,'0.250'),       (7,5,'true'),
  (8,1,'Red'),         (8,3,'OneSize'),
  (9,1,'Black'),       (9,5,'false'),
  (10,2,'1.000'),      (10,5,'false');

-- 8) Inventory
INSERT INTO "inventory" (
  product_id, quantity
) VALUES
  (1, 100),
  (2,   0),
  (3,  -5),
  (4, 500),
  (5,  10),
  (6,1000),
  (7,   1),
  (8,  50),
  (9,999999),
  (10,  0);

-- 9) Carts
INSERT INTO "carts" (
  id, user_id
) VALUES
  (1,1), (2,2), (3,4), (4,6);

-- 10) Cart Items
INSERT INTO "cart_items" (
  cart_id, product_id, quantity
) VALUES
  (1,1,2), (1,4,1),  /* NULL → default 1 */
  (1,6,5),
  (2,2,1),
  (2,3,0),           /* zero quantity */
  (3,5,1000);

-- 11) Discounts
INSERT INTO "discounts" (
  id, code, percent, start_date, end_date, max_usage, usage_count
) VALUES
  (1, 'SAVE10',  10.00, '2025-01-01','2025-12-31', 100, 10),
  (2, 'BULK',   100.00, '2025-01-01','2025-06-30', NULL,  0),
  (3, 'FUTURE',  50.00, '2025-08-01','2025-12-31',  10,  0),
  (4, 'NONE',     0.00, '2025-01-01','2025-12-31',   1,  1),
  (5, 'EXPIRED',  5.00, '2024-01-01','2024-12-31', 100, 50);

-- 12) Orders
INSERT INTO "orders" (
  id, user_id, shipping_address_id, discount_id,
  total_amount, status, placed_at, shipped_at, delivered_at, cancelled_at
) VALUES
  (1, 1, 1,  1,      200.00,    'Pending',   DEFAULT, NULL,           NULL,           NULL),
  (2, 2, 3, NULL,      0.00,    'Shipped', '2025-06-01 14:00:00', '2025-06-02','2025-06-05', NULL),
  (3, 1, 1,  2,      0.00,    'Delivered','2025-05-01 09:00:00', '2025-05-02','2025-05-05', NULL),
  (4, 4, 5,  5,       50.00,    'Cancelled','2025-04-01 12:00:00', NULL,        NULL, '2025-04-02 08:30:00'),
  (5, 6, 7,  3, 9999999.99,    'Pending',   DEFAULT, NULL,           NULL,           NULL);

-- 13) Order Items
INSERT INTO "order_items" (
  order_id, product_id, quantity, price_each
) VALUES
  (1,1,1,799.00), (1,4,2,9.99),
  (2,3,3,19.99),
  (3,6,5,0.00),
  (4,5,1,25.00),
  (5,7,1,9999999.99);

-- 14) Payments
INSERT INTO "payments" (
  order_id, amount, payment_date, status, method, transaction_ref
) VALUES
  (1,   200.00, DEFAULT,      'Pending',        'CreditCard',    NULL),
  (2,     0.00, DEFAULT,      'Successful',     'Wallet',        'TX2002'),
  (3,     0.00, DEFAULT,      'Refunded',       'OnlineBanking', 'TX3003'),
  (4,    50.00, DEFAULT,      'Failed',         'CreditCard',    'TX4004'),
  (5, 9999999.99, DEFAULT,    'Pending',        'OnlineBanking', NULL);

-- 15) Reviews
INSERT INTO "reviews" (
  id, user_id, product_id, rating, comment
) VALUES
  (1, 1, 1, 5, 'Excellent product!'),
  (2, 2, 3, 1, NULL),
  (3, 1, 4, 4, 'Works as expected.'),
  (4, 4, 5, 3, 'Average quality.'),
  (5, 6, 2, 2, 'Not satisfied.'),
  (6, 5, 8, 5, 'Loved “Edge” & Co.!'),
  (7, 3, 6, 5, NULL);
