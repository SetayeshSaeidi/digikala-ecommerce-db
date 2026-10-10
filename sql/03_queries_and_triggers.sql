--1:
WITH RECURSIVE cat_tree AS (
  SELECT id
  FROM categories
  WHERE name = 'Electronics'                 
  UNION ALL
  SELECT c.id
  FROM categories c
  JOIN cat_tree ct ON c.parent_id = ct.id
)
SELECT DISTINCT p.title, p.price
FROM products p
JOIN product_categories pc ON p.id = pc.product_id
JOIN cat_tree ct ON pc.category_id = ct.id
ORDER BY p.price DESC;

--2:
SELECT 
  p.title, 
  ROUND(AVG(r.rating)::numeric, 2) AS average_rating,
  COUNT(*) AS review_count
FROM products p
JOIN reviews r ON p.id = r.product_id
GROUP BY p.title
HAVING COUNT(*) >= 1
ORDER BY average_rating DESC;

--3 : i have applied the distinct discount ids too
SELECT 
  u.email AS username,
  COUNT(o.discount_id) AS discounts_used,
  COUNT(DISTINCT o.discount_id) AS distinct_discount_codes
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE o.discount_id IS NOT NULL
GROUP BY u.email
ORDER BY discounts_used ASC;

--4 :
WITH qualified AS (
  SELECT 
    p.id AS product_id,
    p.title,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    COALESCE(inv.quantity, 0) AS stock_quantity
  FROM products p
  JOIN product_attribute_values pav ON p.id = pav.product_id
  JOIN product_attributes pa ON pav.attribute_id = pa.id
  JOIN order_items oi ON p.id = oi.product_id
  LEFT JOIN inventory inv ON p.id = inv.product_id
  WHERE pa.name = 'Weight'            --can change 
    AND pav.value_text = '0.050'     
  GROUP BY p.id, p.title, inv.quantity
  HAVING COUNT(DISTINCT oi.order_id) >= 2
)
SELECT
  title,
  orders_count,
  stock_quantity
FROM qualified
ORDER BY title;

--5 :
SELECT 
  p.title,
  u.email AS username,
  r.rating,
  o.placed_at AS order_date
FROM reviews r
JOIN users u ON r.user_id = u.id
JOIN products p ON r.product_id = p.id
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id 
  AND o.user_id = u.id   
ORDER BY o.placed_at;

--6:
WITH avg_stock AS (
  SELECT AVG(quantity) AS avg_qty
  FROM inventory
)
SELECT 
  p.title,
  inv.quantity AS stock_quantity,
  p.price
FROM inventory inv
JOIN avg_stock a ON inv.quantity < a.avg_qty
JOIN products p ON p.id = inv.product_id
ORDER BY inv.quantity ASC;

--7:
-- Trigger function: deduct stock when an order item is inserted
CREATE OR REPLACE FUNCTION deduct_inventory_on_order_item_insert()
RETURNS TRIGGER AS $$
DECLARE
  current_qty integer;
BEGIN
  IF NEW.quantity <= 0 THEN
    RAISE EXCEPTION 'Order item quantity must be positive, got %', NEW.quantity;
  END IF;

  SELECT quantity INTO current_qty
  FROM inventory
  WHERE product_id = NEW.product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No inventory record for product %', NEW.product_id;
  END IF;

  IF current_qty < NEW.quantity THEN
    RAISE EXCEPTION 'Insufficient stock for product %. Available: %, required: %',
      NEW.product_id, current_qty, NEW.quantity;
  END IF;

  UPDATE inventory
    SET quantity = quantity - NEW.quantity,
        last_updated = CURRENT_TIMESTAMP
    WHERE product_id = NEW.product_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger that fires after inserting into order_items
CREATE TRIGGER trg_deduct_inventory_after_insert
  AFTER INSERT ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION deduct_inventory_on_order_item_insert();

--test :
-- make sure product exists
INSERT INTO products (id, title, price) VALUES (999, 'Test Product', 10.00)
  ON CONFLICT (id) DO NOTHING;

-- set inventory to a known quantity
INSERT INTO inventory (product_id, quantity)
  VALUES (999, 20)
  ON CONFLICT (product_id) DO UPDATE SET quantity = 20;

-- create an order for some user (assume user 1 exists and has a valid shipping_address_id)
INSERT INTO orders (id, user_id, shipping_address_id, total_amount, status)
  VALUES (999, 1, 1, 0.00, 'Pending')
  ON CONFLICT (id) DO NOTHING;

-- check stock before
SELECT quantity FROM inventory WHERE product_id = 999;  -- expect 20

-- insert order item
INSERT INTO order_items (order_id, product_id, quantity, price_each)
VALUES (999, 999, 5, 10.00);

-- check stock after: should be 15
SELECT quantity FROM inventory WHERE product_id = 999;


--8 :
SELECT 
  c.name AS category_name,
  ROUND(SUM(oi.quantity * oi.price_each)::numeric, 2) AS total_revenue,
  SUM(oi.quantity) AS products_sold
FROM categories c
JOIN product_categories pc ON c.id = pc.category_id
JOIN products p ON p.id = pc.product_id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.id
  AND o.status = 'Delivered'
GROUP BY c.name
HAVING SUM(oi.quantity) > 0
ORDER BY total_revenue DESC;


--9:
WITH user_totals AS (
  SELECT 
    u.email AS username,
    SUM(o.total_amount) AS total_spent,
    COUNT(*) AS orders_count
  FROM orders o
  JOIN users u ON o.user_id = u.id
  GROUP BY u.email
),
avg_spent AS (
  SELECT AVG(total_spent) AS avg_total
  FROM user_totals
)
SELECT 
  username,
  total_spent,
  orders_count
FROM user_totals
WHERE total_spent > (SELECT avg_total FROM avg_spent);


--10:
WITH filtered_products AS (
  SELECT p.id, p.title
  FROM products p
  JOIN product_attribute_values pav_color 
    ON p.id = pav_color.product_id
  JOIN product_attributes a_color 
    ON pav_color.attribute_id = a_color.id 
   AND a_color.name = 'Color' 
   AND pav_color.value_text = 'Black'          
  JOIN product_attribute_values pav_weight 
    ON p.id = pav_weight.product_id
  JOIN product_attributes a_weight 
    ON pav_weight.attribute_id = a_weight.id 
   AND a_weight.name = 'Weight' 
   AND CAST(pav_weight.value_text AS numeric) = 1.0  
),
order_stats AS (
  SELECT 
    oi.product_id,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    SUM(oi.quantity) AS total_ordered_quantity
  FROM order_items oi
  GROUP BY oi.product_id
  HAVING COUNT(DISTINCT oi.order_id) >= 3
     AND SUM(oi.quantity) > 5
),
review_stats AS (
  SELECT 
    product_id,
    ROUND(AVG(rating)::numeric, 2) AS average_rating
  FROM reviews
  GROUP BY product_id
),
category_counts AS (
  SELECT 
    product_id,
    COUNT(DISTINCT category_id) AS category_count
  FROM product_categories
  GROUP BY product_id
)
SELECT 
  fp.title,
  os.total_ordered_quantity,
  rs.average_rating,
  COALESCE(cc.category_count, 0) AS category_count
FROM filtered_products fp
JOIN order_stats os ON fp.id = os.product_id
JOIN review_stats rs ON fp.id = rs.product_id         -- ensures at least one review
LEFT JOIN category_counts cc ON fp.id = cc.product_id;



--11:
SELECT 
  u.email AS username,
  SUM(ci.quantity) AS item_count,
  ROUND(SUM(ci.quantity * p.price)::numeric, 2) AS total_value
FROM users u
JOIN carts c ON c.user_id = u.id
JOIN cart_items ci ON ci.cart_id = c.id AND ci.quantity > 0
JOIN products p ON p.id = ci.product_id
WHERE u.is_premium = true
GROUP BY u.email
HAVING SUM(ci.quantity) > 0;


--12:
WITH review_counts AS (
  SELECT 
    p.id AS product_id,
    p.title,
    COUNT(r.id) AS review_count
  FROM products p
  LEFT JOIN reviews r ON p.id = r.product_id
  GROUP BY p.id, p.title
),
avg_reviews AS (
  SELECT AVG(review_count) AS avg_rev
  FROM review_counts
)
SELECT 
  rc.title,
  rc.review_count,
  COALESCE(inv.quantity, 0) AS stock_quantity
FROM review_counts rc
JOIN avg_reviews a ON rc.review_count > a.avg_rev
JOIN inventory inv ON rc.product_id = inv.product_id
WHERE rc.review_count > 0
ORDER BY rc.review_count;


--13:
-- 1. Log table for recording who used the discount and when
CREATE TABLE IF NOT EXISTS discount_usage_log (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id),
  discount_id bigint NOT NULL REFERENCES discounts(id),
  order_id bigint NOT NULL REFERENCES orders(id),
  usage_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Trigger function: increment discount.usage_count and record the usage
CREATE OR REPLACE FUNCTION increment_discount_usage_and_log()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.discount_id IS NOT NULL THEN
    -- increment the counter on the discount
    UPDATE discounts
      SET usage_count = usage_count + 1,
          updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.discount_id;

    -- log the usage detail
    INSERT INTO discount_usage_log (user_id, discount_id, order_id, usage_date)
    VALUES (NEW.user_id, NEW.discount_id, NEW.id, CURRENT_TIMESTAMP);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger: fires after inserting an order with a non-null discount_id
DROP TRIGGER IF EXISTS trg_increment_discount_usage_on_order_insert ON orders;
CREATE TRIGGER trg_increment_discount_usage_on_order_insert
  AFTER INSERT ON orders
  FOR EACH ROW
  WHEN (NEW.discount_id IS NOT NULL)
  EXECUTE FUNCTION increment_discount_usage_and_log();

--test:
-- ensure log table exists and clean previous test entries for clarity
TRUNCATE discount_usage_log RESTART IDENTITY;

-- reset a discount’s usage_count to a known value (e.g., discount 1)
UPDATE discounts SET usage_count = 10 WHERE id = 1;

-- usage_count should have incremented by 1
SELECT usage_count FROM discounts WHERE id = 1;  -- expect 10

-- insert order with a non-null discount_id
INSERT INTO orders (id,user_id, shipping_address_id, discount_id, total_amount, status)
VALUES (6,1, 1, 1, 100.00, 'Pending')
RETURNING id;

-- a log entry was created
SELECT user_id, discount_id, order_id, usage_date
FROM discount_usage_log
WHERE discount_id = 1
ORDER BY usage_date DESC
LIMIT 1;


--14:

WITH user_item_counts AS (
  SELECT o.user_id, COALESCE(SUM(oi.quantity), 0) AS total_items
  FROM orders o
  LEFT JOIN order_items oi ON oi.order_id = o.id
  GROUP BY o.user_id
),
user_spent AS (
  SELECT user_id, ROUND(SUM(total_amount)::numeric, 2) AS total_spent
  FROM orders
  GROUP BY user_id
)
SELECT 
  u.email AS username,
  COALESCE(uic.total_items, 0) AS total_items,
  us.total_spent
FROM users u
JOIN user_spent us ON u.id = us.user_id        
LEFT JOIN user_item_counts uic ON u.id = uic.user_id
ORDER BY us.total_spent DESC;


--15:
WITH RECURSIVE cat_tree AS (
  SELECT id
  FROM categories
  WHERE name = 'Electronics' 
  UNION ALL
  SELECT c.id
  FROM categories c
  JOIN cat_tree ct ON c.parent_id = ct.id
),
avg_price AS (
  SELECT AVG(p.price) AS avg_price
  FROM products p
  JOIN product_categories pc ON p.id = pc.product_id
  JOIN cat_tree ct ON pc.category_id = ct.id
)
SELECT 
  p.title,
  p.price,
  COALESCE(inv.quantity, 0) AS stock_quantity
FROM products p
LEFT JOIN inventory inv ON p.id = inv.product_id
WHERE p.price > (SELECT avg_price FROM avg_price)
ORDER BY p.price DESC;

--16:
WITH avg_order AS (
  SELECT AVG(total_amount) AS avg_total
  FROM orders
),
user_cart AS (
  SELECT 
    u.email AS username,
    SUM(ci.quantity) AS item_count,
    SUM(ci.quantity * p.price) AS total_cart_value
  FROM users u
  JOIN carts c ON c.user_id = u.id
  JOIN cart_items ci ON ci.cart_id = c.id AND ci.quantity > 0
  JOIN products p ON p.id = ci.product_id
  GROUP BY u.email
)
SELECT 
  uc.username,
  ROUND(uc.total_cart_value::numeric, 2) AS total_cart_value,
  uc.item_count
FROM user_cart uc
CROSS JOIN avg_order ao
WHERE uc.total_cart_value > ao.avg_total
ORDER BY uc.total_cart_value DESC;


--17:
SELECT 
  u.email AS username,
  a.id AS address_id,
  COUNT(o.id) AS order_count,
  ROUND(SUM(o.total_amount)::numeric, 2) AS total_spent
FROM users u
JOIN addresses a 
  ON a.user_id = u.id 
  AND a.is_default = true
JOIN orders o 
  ON o.shipping_address_id = a.id 
  AND o.status = 'Delivered'
GROUP BY u.email, a.id
HAVING COUNT(o.id) > 0
ORDER BY u.email, a.id;

--18: 2 different categories not parent 
SELECT 
  p.title,
  cat_count.category_count,
  ROUND(rv.avg_rating::numeric, 2) AS average_rating
FROM products p
JOIN (
  SELECT product_id,
         COUNT(DISTINCT category_id) AS category_count
  FROM product_categories
  GROUP BY product_id
  HAVING COUNT(DISTINCT category_id) >= 2
) cat_count ON p.id = cat_count.product_id
JOIN (
  SELECT product_id,
         AVG(rating) AS avg_rating
  FROM reviews
  GROUP BY product_id
  HAVING AVG(rating) >= 4
) rv ON p.id = rv.product_id
ORDER BY rv.avg_rating DESC;


--19:
-- 1. alter flag to mark premium-only discounts
ALTER TABLE discounts
  ADD COLUMN IF NOT EXISTS premium_only boolean NOT NULL DEFAULT false;

-- 2. Table to log usages of premium-only discounts
CREATE TABLE IF NOT EXISTS premium_discount_usage (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id),
  discount_id bigint NOT NULL REFERENCES discounts(id),
  order_id bigint NOT NULL REFERENCES orders(id),
  usage_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Trigger function: when an order is inserted, if its discount is premium-only, log it
CREATE OR REPLACE FUNCTION log_premium_discount_usage_on_order_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- only proceed if there is a discount and it's marked premium-only
  IF NEW.discount_id IS NOT NULL THEN
    PERFORM 1
    FROM discounts
    WHERE id = NEW.discount_id
      AND premium_only = true;

    IF FOUND THEN
      INSERT INTO premium_discount_usage (user_id, discount_id, order_id, usage_date)
      VALUES (NEW.user_id, NEW.discount_id, NEW.id, CURRENT_TIMESTAMP);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger that fires after inserting into orders
CREATE TRIGGER trg_log_premium_discount_usage_after_order_insert
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION log_premium_discount_usage_on_order_insert();

--test 

INSERT INTO discounts (id, code, percent, start_date, end_date, max_usage, usage_count, premium_only)
VALUES 
  (100, 'PREMTEST', 20.00, '2025-01-01', '2025-12-31', NULL, 0, true)  
ON CONFLICT (id) DO UPDATE SET premium_only = true, code='PREMTEST';


INSERT INTO orders (id,user_id, shipping_address_id, discount_id, total_amount, status)
VALUES (8,1, 1, 100, 150.00, 'Pending');

-- Expect one log row for this order
SELECT user_id, discount_id, order_id, usage_date
FROM premium_discount_usage
WHERE discount_id = 100
ORDER BY usage_date DESC;


--20 :
-- 1. Log table
CREATE TABLE IF NOT EXISTS price_change_log (
  id bigserial PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id),
  old_price numeric(12,2) NOT NULL,
  new_price numeric(12,2) NOT NULL,
  change_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Trigger function
CREATE OR REPLACE FUNCTION log_price_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.price IS DISTINCT FROM OLD.price THEN
    INSERT INTO price_change_log (product_id, old_price, new_price, change_date)
    VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger on price updates
CREATE TRIGGER trg_log_price_change
  AFTER UPDATE OF price ON products
  FOR EACH ROW
  WHEN (OLD.price IS DISTINCT FROM NEW.price)
  EXECUTE FUNCTION log_price_change();

--test :
-- clean log
TRUNCATE price_change_log RESTART IDENTITY;

-- ensure a test product exists
INSERT INTO products (id, title, description, price, upload_date)
VALUES (999, 'PriceTest', 'Test product for price change', 100.00, CURRENT_DATE)
  ON CONFLICT (id) DO UPDATE 
    SET title = 'PriceTest', description='Test product for price change', price = 100.00;

-- change price from 100.00 to 120.00
UPDATE products
SET price = 120.00
WHERE id = 999;

-- inspect log
SELECT product_id, old_price, new_price, change_date
FROM price_change_log
WHERE product_id = 999
ORDER BY change_date DESC;


--21:
CREATE OR REPLACE FUNCTION assign_first_address_if_missing()
RETURNS TRIGGER AS $$
DECLARE
  addr_id bigint;
BEGIN
  IF NEW.shipping_address_id IS NULL THEN
    -- prefer the default address, otherwise the earliest one
    SELECT id INTO addr_id
    FROM addresses
    WHERE user_id = NEW.user_id
    ORDER BY (is_default IS TRUE) DESC, created_at ASC, id ASC
    LIMIT 1;

    IF addr_id IS NULL THEN
      RAISE EXCEPTION 'Cannot create order: user % has no address', NEW.user_id;
    END IF;

    NEW.shipping_address_id := addr_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_address_before_order_insert
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION assign_first_address_if_missing();

--test
INSERT INTO orders (id,user_id, discount_id, total_amount, status)
VALUES (7,1, NULL, 50.00, 'Pending')
RETURNING id, shipping_address_id;


  --22:
WITH product_cart_totals AS (
  SELECT 
    p.id AS product_id,
    p.title,
    pav.value_text AS attribute_value,
    SUM(ci.quantity) AS total_cart_quantity,
    COUNT(DISTINCT c.user_id) AS distinct_user_count
  FROM products p
  JOIN product_attribute_values pav ON p.id = pav.product_id
  JOIN product_attributes pa ON pav.attribute_id = pa.id
  JOIN cart_items ci ON p.id = ci.product_id AND ci.quantity > 0
  JOIN carts c ON ci.cart_id = c.id
  WHERE pa.name = 'Color'
    AND pav.value_text = 'Black'
  GROUP BY p.id, p.title, pav.value_text
),
avg_cart_quantity AS (
  SELECT AVG(sub.total_cart_quantity) AS avg_qty
  FROM (
    SELECT ci.product_id, SUM(ci.quantity) AS total_cart_quantity
    FROM cart_items ci
    JOIN carts c ON ci.cart_id = c.id
    WHERE ci.quantity > 0
    GROUP BY ci.product_id
  ) sub
)
SELECT 
  pct.title,
  pct.attribute_value,
  pct.total_cart_quantity,
  COALESCE(inv.quantity, 0) AS stock_quantity,
  pct.distinct_user_count
FROM product_cart_totals pct
CROSS JOIN avg_cart_quantity ac
JOIN inventory inv ON pct.product_id = inv.product_id
WHERE pct.distinct_user_count >= 3
  AND pct.total_cart_quantity > ac.avg_qty
ORDER BY pct.total_cart_quantity DESC;

--23
WITH premium_orders AS (
  SELECT o.id, o.user_id, o.total_amount
  FROM orders o
  JOIN users u ON o.user_id = u.id
  WHERE u.is_premium = true
),
avg_premium_order AS (
  SELECT AVG(total_amount) AS avg_order_value
  FROM premium_orders
),
filtered_products AS (
  -- products having both attribute conditions
  SELECT p.id, p.title
  FROM products p
  JOIN product_attribute_values pav1 
    ON p.id = pav1.product_id
  JOIN product_attributes pa1 
    ON pav1.attribute_id = pa1.id 
   AND pa1.name = 'Color'           
   AND pav1.value_text = 'Black'
  JOIN product_attribute_values pav2 
    ON p.id = pav2.product_id
  JOIN product_attributes pa2 
    ON pav2.attribute_id = pa2.id 
   AND pa2.name = 'Weight'
   AND pav2.value_text = '1.0'
),
product_premium_stats AS (
  SELECT 
    fp.id AS product_id,
    fp.title,
    SUM(oi.quantity * oi.price_each) AS total_order_value,
    COUNT(DISTINCT o.user_id) AS premium_user_count
  FROM filtered_products fp
  JOIN order_items oi ON fp.id = oi.product_id
  JOIN orders o ON oi.order_id = o.id
  JOIN users u ON o.user_id = u.id AND u.is_premium = true
  GROUP BY fp.id, fp.title
  HAVING COUNT(DISTINCT o.user_id) >= 2
)
SELECT 
  pps.title,
  ROUND(pps.total_order_value::numeric, 2) AS total_order_value,
  pps.premium_user_count,
  COALESCE(inv.quantity, 0) AS stock_quantity
FROM product_premium_stats pps
CROSS JOIN avg_premium_order apo
LEFT JOIN inventory inv ON pps.product_id = inv.product_id
WHERE pps.total_order_value > apo.avg_order_value
ORDER BY pps.total_order_value DESC;

--24:
WITH category_order_qty AS (
  SELECT 
    c.id,
    c.name,
    SUM(oi.quantity) AS category_total_qty
  FROM categories c
  JOIN product_categories pc ON c.id = pc.category_id
  JOIN order_items oi ON oi.product_id = pc.product_id
  GROUP BY c.id, c.name
),
avg_category_qty AS (
  SELECT AVG(category_total_qty) AS avg_qty
  FROM category_order_qty
),
good_categories AS (
  SELECT id, name
  FROM category_order_qty
  WHERE category_total_qty > (SELECT avg_qty FROM avg_category_qty)
),
product_orders AS (
  SELECT 
    product_id, 
    SUM(quantity) AS total_ordered_quantity
  FROM order_items
  GROUP BY product_id
),
review_counts AS (
  SELECT 
    product_id,
    COUNT(*) AS review_count
  FROM reviews
  GROUP BY product_id
),
filtered_products AS (
  SELECT 
    p.id AS product_id,
    p.title,
    pav.value_text AS attribute_value
  FROM products p
  JOIN product_attribute_values pav ON p.id = pav.product_id
  JOIN product_attributes pa ON pav.attribute_id = pa.id
  WHERE pa.name = 'Color'
    AND pav.value_text = 'Black'
)
SELECT
  fp.title,
  gc.name AS category_name,
  fp.attribute_value,
  po.total_ordered_quantity,
  rc.review_count
FROM filtered_products fp
JOIN product_categories pc ON fp.product_id = pc.product_id
JOIN good_categories gc ON pc.category_id = gc.id
JOIN product_orders po ON fp.product_id = po.product_id
JOIN review_counts rc ON fp.product_id = rc.product_id;




