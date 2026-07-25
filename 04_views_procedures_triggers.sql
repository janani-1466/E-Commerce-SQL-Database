-- =====================================================================
-- VIEWS, STORED PROCEDURES, AND TRIGGERS
-- =====================================================================
USE ecommerce_db;

-- ---------------------------------------------------------------------
-- VIEWS
-- ---------------------------------------------------------------------

-- View: order summary with customer & payment info
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT o.order_id, c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       o.order_status, o.order_date, o.total_amount,
       p.payment_method, p.payment_status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN payments p ON p.order_id = o.order_id;

-- View: product catalog with category and average rating
CREATE OR REPLACE VIEW vw_product_catalog AS
SELECT p.product_id, p.sku, p.name, cat.name AS category, p.price, p.stock_quantity,
       ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.review_id) AS review_count
FROM products p
LEFT JOIN categories cat ON cat.category_id = p.category_id
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.sku, p.name, cat.name, p.price, p.stock_quantity;

-- View: monthly sales report
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       COUNT(*) AS num_orders,
       SUM(total_amount) AS revenue
FROM orders
WHERE order_status = 'DELIVERED'
GROUP BY month;

-- View: low stock alert
CREATE OR REPLACE VIEW vw_low_stock AS
SELECT product_id, sku, name, stock_quantity, reorder_level
FROM products
WHERE stock_quantity <= reorder_level;

-- ---------------------------------------------------------------------
-- STORED PROCEDURES
-- ---------------------------------------------------------------------

DELIMITER $$

-- Place a new order: validates stock, inserts order + items, deducts inventory.
-- Expects item list as JSON: '[{"product_id":1,"quantity":2}, {"product_id":5,"quantity":1}]'
CREATE PROCEDURE sp_place_order (
    IN p_customer_id   INT,
    IN p_address_id    INT,
    IN p_coupon_id     INT,
    IN p_items_json    JSON,
    OUT p_order_id     INT
)
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_n INT;
    DECLARE v_product_id INT;
    DECLARE v_qty INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_discount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_disc_type VARCHAR(10);
    DECLARE v_disc_value DECIMAL(10,2);
    DECLARE v_min_order DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SET v_n = JSON_LENGTH(p_items_json);

    -- Validate stock for every item first
    WHILE v_i < v_n DO
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items_json, CONCAT('$[', v_i, '].product_id')));
        SET v_qty        = JSON_UNQUOTE(JSON_EXTRACT(p_items_json, CONCAT('$[', v_i, '].quantity')));

        SELECT stock_quantity, price INTO v_stock, v_price
        FROM products WHERE product_id = v_product_id FOR UPDATE;

        IF v_stock IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product in order';
        END IF;

        IF v_stock < v_qty THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for product';
        END IF;

        SET v_subtotal = v_subtotal + (v_price * v_qty);
        SET v_i = v_i + 1;
    END WHILE;

    -- Apply coupon if provided
    IF p_coupon_id IS NOT NULL THEN
        SELECT discount_type, discount_value, min_order_value
        INTO v_disc_type, v_disc_value, v_min_order
        FROM coupons WHERE coupon_id = p_coupon_id
          AND CURDATE() BETWEEN valid_from AND valid_until;

        IF v_subtotal >= v_min_order THEN
            IF v_disc_type = 'PERCENT' THEN
                SET v_discount = v_subtotal * v_disc_value / 100;
            ELSE
                SET v_discount = v_disc_value;
            END IF;
            UPDATE coupons SET times_used = times_used + 1 WHERE coupon_id = p_coupon_id;
        END IF;
    END IF;

    -- Create the order
    INSERT INTO orders (customer_id, address_id, coupon_id, order_status, subtotal, discount_amount, shipping_fee, total_amount)
    VALUES (p_customer_id, p_address_id, p_coupon_id, 'PENDING', v_subtotal, v_discount, 0,
            v_subtotal - v_discount);

    SET p_order_id = LAST_INSERT_ID();

    -- Insert order items and deduct stock
    SET v_i = 0;
    WHILE v_i < v_n DO
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items_json, CONCAT('$[', v_i, '].product_id')));
        SET v_qty        = JSON_UNQUOTE(JSON_EXTRACT(p_items_json, CONCAT('$[', v_i, '].quantity')));

        SELECT price INTO v_price FROM products WHERE product_id = v_product_id;

        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (p_order_id, v_product_id, v_qty, v_price);

        UPDATE products SET stock_quantity = stock_quantity - v_qty WHERE product_id = v_product_id;

        INSERT INTO inventory_log (product_id, change_qty, reason, reference_id)
        VALUES (v_product_id, -v_qty, 'ORDER', p_order_id);

        SET v_i = v_i + 1;
    END WHILE;

    COMMIT;
END$$

-- Cancel an order: restores stock and marks order cancelled
CREATE PROCEDURE sp_cancel_order (
    IN p_order_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE orders SET order_status = 'CANCELLED' WHERE order_id = p_order_id;

    UPDATE products p
    JOIN order_items oi ON oi.product_id = p.product_id
    SET p.stock_quantity = p.stock_quantity + oi.quantity
    WHERE oi.order_id = p_order_id;

    INSERT INTO inventory_log (product_id, change_qty, reason, reference_id)
    SELECT product_id, quantity, 'CANCELLATION', p_order_id
    FROM order_items WHERE order_id = p_order_id;

    COMMIT;
END$$

-- Get a customer's full order history
CREATE PROCEDURE sp_customer_order_history (
    IN p_customer_id INT
)
BEGIN
    SELECT o.order_id, o.order_date, o.order_status, o.total_amount,
           p.name AS product_name, oi.quantity, oi.unit_price
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.customer_id = p_customer_id
    ORDER BY o.order_date DESC;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGERS
-- ---------------------------------------------------------------------

DELIMITER $$

-- Prevent negative stock at the database level (defense in depth)
CREATE TRIGGER trg_products_no_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock quantity cannot go negative';
    END IF;
END$$

-- Auto-update order total_amount whenever an order_item is inserted
CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders
    SET subtotal = (SELECT SUM(line_total) FROM order_items WHERE order_id = NEW.order_id),
        total_amount = (SELECT SUM(line_total) FROM order_items WHERE order_id = NEW.order_id) - discount_amount + shipping_fee
    WHERE order_id = NEW.order_id;
END$$

DELIMITER ;
