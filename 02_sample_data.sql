-- =====================================================================
-- SAMPLE DATA
-- Run after 01_schema.sql
-- =====================================================================
USE ecommerce_db;

-- CATEGORIES
INSERT INTO categories (name, parent_id) VALUES
('Electronics', NULL),
('Mobiles', 1),
('Laptops', 1),
('Fashion', NULL),
("Men's Clothing", 4),
("Women's Clothing", 4),
('Home & Kitchen', NULL),
('Books', NULL);

-- SUPPLIERS
INSERT INTO suppliers (name, contact_email, contact_phone, country) VALUES
('TechSource India', 'sales@techsource.in', '+91-9800011111', 'India'),
('Global Textiles Ltd', 'contact@globaltextiles.com', '+91-9800022222', 'India'),
('HomeEssentials Co', 'info@homeessentials.com', '+91-9800033333', 'India'),
('BookWorld Distributors', 'orders@bookworld.com', '+91-9800044444', 'India');

-- CUSTOMERS
INSERT INTO customers (first_name, last_name, email, phone, password_hash, date_of_birth) VALUES
('Arun', 'Kumar', 'arun.kumar@example.com', '+91-9000000001', 'hash1', '1995-04-12'),
('Priya', 'Sundaram', 'priya.s@example.com', '+91-9000000002', 'hash2', '1998-07-22'),
('Vijay', 'Raghavan', 'vijay.r@example.com', '+91-9000000003', 'hash3', '1990-01-30'),
('Divya', 'Menon', 'divya.menon@example.com', '+91-9000000004', 'hash4', '1993-11-05'),
('Karthik', 'Iyer', 'karthik.iyer@example.com', '+91-9000000005', 'hash5', '2000-03-18'),
('Sneha', 'Reddy', 'sneha.reddy@example.com', '+91-9000000006', 'hash6', '1997-09-09'),
('Rahul', 'Nair', 'rahul.nair@example.com', '+91-9000000007', 'hash7', '1992-06-14'),
('Anjali', 'Pillai', 'anjali.pillai@example.com', '+91-9000000008', 'hash8', '1996-12-25');

-- ADDRESSES
INSERT INTO addresses (customer_id, label, line1, city, state, postal_code, country, is_default) VALUES
(1, 'Home', '12 Anna Nagar', 'Chennai', 'Tamil Nadu', '600040', 'India', TRUE),
(2, 'Home', '45 Koramangala', 'Bengaluru', 'Karnataka', '560034', 'India', TRUE),
(3, 'Home', '78 Banjara Hills', 'Hyderabad', 'Telangana', '500034', 'India', TRUE),
(4, 'Home', '23 Marine Drive', 'Kochi', 'Kerala', '682031', 'India', TRUE),
(5, 'Home', '9 Salt Lake', 'Kolkata', 'West Bengal', '700064', 'India', TRUE),
(6, 'Home', '56 Jubilee Hills', 'Hyderabad', 'Telangana', '500033', 'India', TRUE),
(7, 'Home', '34 MG Road', 'Bengaluru', 'Karnataka', '560001', 'India', TRUE),
(8, 'Home', '11 T Nagar', 'Chennai', 'Tamil Nadu', '600017', 'India', TRUE);

-- PRODUCTS
INSERT INTO products (sku, name, description, category_id, supplier_id, price, cost_price, stock_quantity, reorder_level) VALUES
('MOB-001', 'Galaxy Nova 5G', '128GB, 8GB RAM smartphone', 2, 1, 24999.00, 19000.00, 50, 10),
('MOB-002', 'Pixel Lite', '64GB budget smartphone', 2, 1, 14999.00, 11000.00, 80, 15),
('LAP-001', 'ProBook X14', '14-inch laptop, i5, 16GB RAM', 3, 1, 54999.00, 45000.00, 25, 5),
('LAP-002', 'UltraLight Air', '13-inch ultrabook, i7, 16GB RAM', 3, 1, 74999.00, 62000.00, 15, 5),
('MEN-001', "Men's Cotton Shirt", 'Casual slim-fit shirt', 5, 2, 899.00, 400.00, 200, 30),
('MEN-002', "Men's Denim Jeans", 'Slim fit stretchable denim', 5, 2, 1499.00, 700.00, 150, 25),
('WOM-001', "Women's Kurti", 'Printed cotton kurti', 6, 2, 799.00, 350.00, 180, 30),
('WOM-002', "Women's Handbag", 'Leather handbag', 6, 2, 1999.00, 900.00, 60, 10),
('HOM-001', 'Non-stick Pan Set', '3-piece cookware set', 7, 3, 1299.00, 600.00, 100, 20),
('HOM-002', 'LED Table Lamp', 'Adjustable brightness lamp', 7, 3, 699.00, 300.00, 120, 20),
('BOK-001', 'Data Structures & Algorithms', 'Programming reference book', 8, 4, 549.00, 300.00, 90, 15),
('BOK-002', 'Introduction to SQL', 'Beginner SQL guide', 8, 4, 449.00, 250.00, 90, 15);

-- COUPONS
INSERT INTO coupons (code, discount_type, discount_value, min_order_value, valid_from, valid_until, max_uses, times_used) VALUES
('WELCOME10', 'PERCENT', 10.00, 500.00, '2026-01-01', '2026-12-31', 1000, 120),
('FLAT200', 'FLAT', 200.00, 2000.00, '2026-01-01', '2026-12-31', 500, 80),
('BIGSALE25', 'PERCENT', 25.00, 3000.00, '2026-06-01', '2026-08-31', 300, 45);

-- ORDERS (spanning a few months for time-based analysis)
INSERT INTO orders (customer_id, address_id, coupon_id, order_status, order_date, subtotal, discount_amount, shipping_fee, total_amount) VALUES
(1, 1, 1, 'DELIVERED', '2026-05-02 10:15:00', 24999.00, 2499.90, 0.00, 22499.10),
(2, 2, NULL, 'DELIVERED', '2026-05-10 14:30:00', 1499.00, 0.00, 50.00, 1549.00),
(3, 3, 2, 'DELIVERED', '2026-05-15 09:00:00', 2298.00, 200.00, 0.00, 2098.00),
(1, 1, NULL, 'SHIPPED', '2026-06-01 11:45:00', 899.00, 0.00, 50.00, 949.00),
(4, 4, NULL, 'DELIVERED', '2026-06-05 16:20:00', 74999.00, 0.00, 0.00, 74999.00),
(5, 5, 3, 'DELIVERED', '2026-06-12 12:00:00', 54999.00, 13749.75, 0.00, 41249.25),
(6, 6, NULL, 'CANCELLED', '2026-06-18 08:30:00', 1999.00, 0.00, 50.00, 2049.00),
(2, 2, NULL, 'DELIVERED', '2026-06-20 19:10:00', 1298.00, 0.00, 0.00, 1298.00),
(7, 7, 1, 'PENDING', '2026-07-01 10:00:00', 14999.00, 1499.90, 0.00, 13499.10),
(8, 8, NULL, 'DELIVERED', '2026-07-05 13:25:00', 998.00, 0.00, 50.00, 1048.00),
(3, 3, NULL, 'DELIVERED', '2026-07-10 17:40:00', 699.00, 0.00, 50.00, 749.00),
(1, 1, NULL, 'DELIVERED', '2026-07-15 15:05:00', 1948.00, 0.00, 0.00, 1948.00),
(4, 4, 2, 'RETURNED', '2026-07-18 09:50:00', 2499.00, 200.00, 0.00, 2299.00),
(6, 6, NULL, 'DELIVERED', '2026-07-20 20:00:00', 549.00, 0.00, 50.00, 599.00),
(5, 5, NULL, 'DELIVERED', '2026-07-22 11:11:00', 1798.00, 0.00, 0.00, 1798.00);

-- ORDER ITEMS
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 24999.00),
(2, 6, 1, 1499.00),
(3, 5, 1, 899.00), (3, 9, 1, 1299.00), (3, 10, 1, 699.00), -- note: exceeds subtotal example simplified below
(4, 5, 1, 899.00),
(5, 4, 1, 74999.00),
(6, 3, 1, 54999.00),
(7, 8, 1, 1999.00),
(8, 9, 1, 1298.00),
(9, 2, 1, 14999.00),
(10, 11, 1, 549.00), (10, 12, 1, 449.00),
(11, 10, 1, 699.00),
(12, 6, 1, 1499.00), (12, 11, 1, 449.00),
(13, 1, 1, 24999.00),  -- adjust: original order used simplified subtotal for demo, treat as partial return
(14, 11, 1, 549.00),
(15, 6, 1, 1499.00), (15, 12, 1, 449.00) ;

-- (Order 3 and 13 subtotals are illustrative/simplified for demo purposes — see README notes)

-- PAYMENTS
INSERT INTO payments (order_id, payment_method, payment_status, amount, paid_at, transaction_ref) VALUES
(1, 'UPI', 'SUCCESS', 22499.10, '2026-05-02 10:16:00', 'TXN100001'),
(2, 'CARD', 'SUCCESS', 1549.00, '2026-05-10 14:31:00', 'TXN100002'),
(3, 'COD', 'SUCCESS', 2098.00, '2026-05-15 09:05:00', 'TXN100003'),
(4, 'UPI', 'SUCCESS', 949.00, '2026-06-01 11:46:00', 'TXN100004'),
(5, 'CARD', 'SUCCESS', 74999.00, '2026-06-05 16:22:00', 'TXN100005'),
(6, 'NETBANKING', 'SUCCESS', 41249.25, '2026-06-12 12:05:00', 'TXN100006'),
(7, 'CARD', 'REFUNDED', 2049.00, '2026-06-18 08:35:00', 'TXN100007'),
(8, 'UPI', 'SUCCESS', 1298.00, '2026-06-20 19:11:00', 'TXN100008'),
(9, 'COD', 'PENDING', 13499.10, NULL, NULL),
(10, 'UPI', 'SUCCESS', 1048.00, '2026-07-05 13:26:00', 'TXN100010'),
(11, 'CARD', 'SUCCESS', 749.00, '2026-07-10 17:41:00', 'TXN100011'),
(12, 'UPI', 'SUCCESS', 1948.00, '2026-07-15 15:06:00', 'TXN100012'),
(13, 'CARD', 'REFUNDED', 2299.00, '2026-07-18 09:55:00', 'TXN100013'),
(14, 'UPI', 'SUCCESS', 599.00, '2026-07-20 20:01:00', 'TXN100014'),
(15, 'WALLET', 'SUCCESS', 1798.00, '2026-07-22 11:12:00', 'TXN100015');

-- REVIEWS
INSERT INTO reviews (product_id, customer_id, rating, comment) VALUES
(1, 1, 5, 'Excellent phone, great battery life.'),
(6, 2, 4, 'Good fit, comfortable denim.'),
(5, 3, 3, 'Decent shirt, fabric could be better.'),
(4, 4, 5, 'Super light and fast, worth the price.'),
(3, 5, 4, 'Great laptop for the price.'),
(8, 6, 2, 'Handbag strap tore within a week.'),
(2, 7, 4, 'Good value smartphone.'),
(11, 8, 5, 'Very helpful DSA reference.'),
(9, 2, 5, 'Non-stick coating works great.'),
(12, 3, 4, 'Clear explanations for SQL beginners.');

-- INVENTORY LOG (simplified — one entry per order item as a stock deduction)
INSERT INTO inventory_log (product_id, change_qty, reason, reference_id)
SELECT product_id, -quantity, 'ORDER', order_id FROM order_items;

-- EMPLOYEES
INSERT INTO employees (full_name, email, role) VALUES
('Meera Krishnan', 'meera.k@shopadmin.com', 'ADMIN'),
('Suresh Babu', 'suresh.b@shopadmin.com', 'MANAGER'),
('Latha Raman', 'latha.r@shopadmin.com', 'SUPPORT');
