-- =====================================================================
-- E-COMMERCE STORE DATABASE — SCHEMA
-- Target: MySQL 8.0+ (uses window functions, CTEs, JSON, generated cols)
-- =====================================================================

DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_db;

-- ---------------------------------------------------------------------
-- CUSTOMERS
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    password_hash   VARCHAR(255) NOT NULL,
    date_of_birth   DATE,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active       BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ADDRESSES (one customer -> many addresses)
-- ---------------------------------------------------------------------
CREATE TABLE addresses (
    address_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    label           VARCHAR(30) DEFAULT 'Home',      -- Home / Work / Other
    line1           VARCHAR(150) NOT NULL,
    line2           VARCHAR(150),
    city            VARCHAR(80)  NOT NULL,
    state           VARCHAR(80)  NOT NULL,
    postal_code     VARCHAR(20)  NOT NULL,
    country         VARCHAR(80)  NOT NULL DEFAULT 'India',
    is_default      BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CATEGORIES (self-referencing for subcategories)
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    parent_id       INT NULL,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- SUPPLIERS
-- ---------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(120) NOT NULL,
    contact_email   VARCHAR(120),
    contact_phone   VARCHAR(20),
    country         VARCHAR(80)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PRODUCTS
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    sku             VARCHAR(40) NOT NULL UNIQUE,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    category_id     INT,
    supplier_id     INT,
    price           DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    cost_price      DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
    stock_quantity  INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level   INT NOT NULL DEFAULT 10,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_price ON products(price);

-- ---------------------------------------------------------------------
-- PRODUCT IMAGES
-- ---------------------------------------------------------------------
CREATE TABLE product_images (
    image_id        INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    image_url       VARCHAR(255) NOT NULL,
    is_primary      BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- COUPONS
-- ---------------------------------------------------------------------
CREATE TABLE coupons (
    coupon_id       INT AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(30) NOT NULL UNIQUE,
    discount_type   ENUM('PERCENT','FLAT') NOT NULL,
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(10,2) DEFAULT 0,
    valid_from      DATE NOT NULL,
    valid_until     DATE NOT NULL,
    max_uses        INT DEFAULT NULL,
    times_used      INT DEFAULT 0
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CART & CART ITEMS
-- ---------------------------------------------------------------------
CREATE TABLE carts (
    cart_id         INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cart_items (
    cart_item_id    INT AUTO_INCREMENT PRIMARY KEY,
    cart_id         INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL CHECK (quantity > 0),
    added_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY uq_cart_product (cart_id, product_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ORDERS
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    address_id      INT NOT NULL,
    coupon_id       INT NULL,
    order_status    ENUM('PENDING','CONFIRMED','SHIPPED','DELIVERED','CANCELLED','RETURNED')
                    NOT NULL DEFAULT 'PENDING',
    order_date      DATETIME DEFAULT CURRENT_TIMESTAMP,
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_fee    DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id),
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
) ENGINE=InnoDB;

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);

-- ---------------------------------------------------------------------
-- ORDER ITEMS (price captured at time of purchase)
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(10,2) NOT NULL,
    line_total      DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ---------------------------------------------------------------------
-- PAYMENTS
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL,
    payment_method  ENUM('CARD','UPI','NETBANKING','COD','WALLET') NOT NULL,
    payment_status  ENUM('PENDING','SUCCESS','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    amount          DECIMAL(12,2) NOT NULL,
    paid_at         DATETIME DEFAULT NULL,
    transaction_ref VARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- REVIEWS
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
    review_id       INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    customer_id     INT NOT NULL,
    rating          TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    UNIQUE KEY uq_review_once (product_id, customer_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- INVENTORY LOG (audit trail for stock changes)
-- ---------------------------------------------------------------------
CREATE TABLE inventory_log (
    log_id          INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    change_qty      INT NOT NULL,             -- negative = stock removed
    reason          VARCHAR(100) NOT NULL,    -- 'ORDER', 'RESTOCK', 'ADJUSTMENT', 'RETURN'
    reference_id    INT,                      -- e.g. order_id
    changed_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- EMPLOYEES / ADMIN USERS
-- ---------------------------------------------------------------------
CREATE TABLE employees (
    employee_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    role            ENUM('ADMIN','MANAGER','SUPPORT') NOT NULL DEFAULT 'SUPPORT',
    hired_at        DATE DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;
