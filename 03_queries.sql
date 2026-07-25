-- =====================================================================
-- ANALYTICAL QUERIES
-- Run after schema + sample data are loaded
-- =====================================================================
USE ecommerce_db;

-- 1. List all customers with their default shipping city
SELECT c.customer_id, c.first_name, c.last_name, a.city, a.state
FROM customers c
JOIN addresses a ON a.customer_id = c.customer_id AND a.is_default = TRUE;

-- 2. Total revenue and order count per customer (delivered orders only)
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COUNT(o.order_id) AS total_orders,
       SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC;

-- 3. Best-selling products by quantity sold
SELECT p.product_id, p.name, SUM(oi.quantity) AS units_sold, SUM(oi.line_total) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
ORDER BY units_sold DESC
LIMIT 5;

-- 4. Monthly revenue trend (delivered orders)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(total_amount) AS revenue
FROM orders
WHERE order_status = 'DELIVERED'
GROUP BY month
ORDER BY month;

-- 5. Products currently below reorder level (low stock alert)
SELECT product_id, name, stock_quantity, reorder_level
FROM products
WHERE stock_quantity <= reorder_level;

-- 6. Average product rating with review count (only products with reviews)
SELECT p.product_id, p.name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.review_id) AS review_count
FROM products p
JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name
ORDER BY avg_rating DESC;

-- 7. Customers who have never placed an order (LEFT JOIN + NULL check)
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- 8. Category-wise revenue breakdown
SELECT cat.name AS category, SUM(oi.line_total) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
GROUP BY cat.name
ORDER BY revenue DESC;

-- 9. Running total of daily revenue using a window function
SELECT order_date_only, daily_revenue,
       SUM(daily_revenue) OVER (ORDER BY order_date_only) AS running_total
FROM (
    SELECT DATE(order_date) AS order_date_only, SUM(total_amount) AS daily_revenue
    FROM orders
    WHERE order_status = 'DELIVERED'
    GROUP BY DATE(order_date)
) daily
ORDER BY order_date_only;

-- 10. Rank customers by total spend using RANK()
SELECT customer_id, customer_name, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM (
    SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
           SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'DELIVERED'
    GROUP BY c.customer_id, customer_name
) spend_summary;

-- 11. Products never ordered (NOT EXISTS subquery)
SELECT p.product_id, p.name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
);

-- 12. Orders with above-average order value (correlated subquery)
SELECT order_id, customer_id, total_amount
FROM orders
WHERE total_amount > (SELECT AVG(total_amount) FROM orders)
ORDER BY total_amount DESC;

-- 13. Coupon usage effectiveness: total discount given per coupon
SELECT co.code, co.discount_type, co.discount_value,
       COUNT(o.order_id) AS times_applied,
       SUM(o.discount_amount) AS total_discount_given
FROM coupons co
LEFT JOIN orders o ON o.coupon_id = co.coupon_id
GROUP BY co.code, co.discount_type, co.discount_value;

-- 14. Payment method distribution (successful payments only)
SELECT payment_method, COUNT(*) AS num_payments, SUM(amount) AS total_amount
FROM payments
WHERE payment_status = 'SUCCESS'
GROUP BY payment_method
ORDER BY total_amount DESC;

-- 15. Top 3 highest-rated products per category (window function + filtering)
WITH ranked_products AS (
    SELECT p.product_id, p.name, cat.name AS category,
           AVG(r.rating) AS avg_rating,
           ROW_NUMBER() OVER (PARTITION BY cat.category_id ORDER BY AVG(r.rating) DESC) AS rn
    FROM products p
    JOIN categories cat ON cat.category_id = p.category_id
    JOIN reviews r ON r.product_id = p.product_id
    GROUP BY p.product_id, p.name, cat.name, cat.category_id
)
SELECT category, name, ROUND(avg_rating, 2) AS avg_rating
FROM ranked_products
WHERE rn <= 3
ORDER BY category, avg_rating DESC;

-- 16. Customer lifetime value with first and most recent order date
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       MIN(o.order_date) AS first_order, MAX(o.order_date) AS latest_order,
       SUM(o.total_amount) AS lifetime_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, customer_name
ORDER BY lifetime_value DESC;

-- 17. Order fulfillment funnel: count of orders by status
SELECT order_status, COUNT(*) AS num_orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;

-- 18. Products with profit margin (price vs cost_price)
SELECT product_id, name, price, cost_price,
       ROUND(price - cost_price, 2) AS profit_per_unit,
       ROUND(100.0 * (price - cost_price) / price, 1) AS margin_pct
FROM products
ORDER BY margin_pct DESC;

-- 19. Repeat customers (more than 1 delivered order)
SELECT customer_id, COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'DELIVERED'
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 20. Products frequently bought together (self-join on order_items)
SELECT oi1.product_id AS product_a, oi2.product_id AS product_b, COUNT(*) AS times_together
FROM order_items oi1
JOIN order_items oi2
     ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
GROUP BY oi1.product_id, oi2.product_id
ORDER BY times_together DESC;

-- 21. Month-over-month revenue growth percentage (window LAG)
SELECT month, revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_growth_pct
FROM (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(total_amount) AS revenue
    FROM orders
    WHERE order_status = 'DELIVERED'
    GROUP BY month
) monthly
ORDER BY month;

-- 22. Full order detail view (customer, items, product names) for a specific order
SELECT o.order_id, c.first_name, c.last_name, p.name AS product, oi.quantity, oi.unit_price, oi.line_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_id = 1;
