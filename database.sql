-- ============================================================
-- E-Commerce Order Management System - Complete Database Schema
-- ============================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS ecommerce_system;
USE ecommerce_system;

-- ============================================================
-- Table 1: Inventory
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    quantity_available INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_name (product_name),
    INDEX idx_quantity (quantity_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 2: Customers
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    loyalty_points INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_loyalty_points (loyalty_points)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 3: Orders
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0.00,
    tax DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 4: Order Items
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discounted_price DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0.00,
    line_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES inventory(product_id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 5: Pricing Rules
-- ============================================================
CREATE TABLE IF NOT EXISTS pricing_rules (
    rule_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    min_quantity INT NOT NULL,
    discount_percentage DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES inventory(product_id),
    INDEX idx_product_id (product_id),
    UNIQUE KEY unique_product_min_qty (product_id, min_quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 6: Tax Rates
-- ============================================================
CREATE TABLE IF NOT EXISTS tax_rates (
    region VARCHAR(50) PRIMARY KEY,
    tax_rate DECIMAL(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table 7: Notification Log
-- ============================================================
CREATE TABLE IF NOT EXISTS notification_log (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_order_id (order_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_sent_at (sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Sample Data: Inventory
-- ============================================================
INSERT INTO inventory (product_name, quantity_available, unit_price) VALUES
('Laptop Dell XPS 15', 50, 25999.99),
('Wireless Mouse Logitech', 200, 299.99),
('Mechanical Keyboard RGB', 150, 799.99),
('4K Monitor 27 inch', 75, 5999.99),
('Noise Cancelling Headphones', 100, 1499.99),
('USB-C Hub 7-in-1', 180, 349.99),
('External SSD 1TB', 90, 1899.99),
('Webcam HD 1080p', 120, 599.99),
('Gaming Chair Ergonomic', 40, 3499.99),
('Desk Lamp LED', 160, 249.99);

-- ============================================================
-- Sample Data: Customers
-- ============================================================
INSERT INTO customers (name, email, phone, loyalty_points) VALUES
('Ahmed Hassan', 'ahmed.hassan@example.com', '01012345678', 150),
('Sara Mohamed', 'sara.mohamed@example.com', '01098765432', 320),
('Omar Ali', 'omar.ali@example.com', '01055555555', 75),
('Fatima Ibrahim', 'fatima.ibrahim@example.com', '01123456789', 200),
('Mahmoud Khalil', 'mahmoud.khalil@example.com', '01087654321', 450);

-- ============================================================
-- Sample Data: Pricing Rules
-- ============================================================
INSERT INTO pricing_rules (product_id, min_quantity, discount_percentage) VALUES
-- Laptop: 5+ units = 10% off, 10+ units = 15% off
(1, 5, 10.00),
(1, 10, 15.00),
-- Mouse: 10+ units = 15% off, 20+ units = 20% off
(2, 10, 15.00),
(2, 20, 20.00),
-- Keyboard: 10+ units = 12% off
(3, 10, 12.00),
-- Monitor: 5+ units = 8% off
(4, 5, 8.00),
-- Headphones: 5+ units = 10% off
(5, 5, 10.00),
-- USB Hub: 15+ units = 18% off
(6, 15, 18.00),
-- SSD: 10+ units = 12% off
(7, 10, 12.00),
-- Webcam: 8+ units = 10% off
(8, 8, 10.00),
-- Gaming Chair: 3+ units = 5% off
(9, 3, 5.00),
-- Desk Lamp: 12+ units = 15% off
(10, 12, 15.00);

-- ============================================================
-- Sample Data: Tax Rates
-- ============================================================
INSERT INTO tax_rates (region, tax_rate) VALUES
('asyut', 17.00),
('Alexandria', 14.00),
('Giza', 14.00),
('Luxor', 14.00),
('Aswan', 14.00),
('Default', 14.00);

-- ============================================================
-- Create Database User
-- ============================================================
-- Create user with limited privileges for security
CREATE USER IF NOT EXISTS 'ecommerce_user'@'localhost' IDENTIFIED BY '123456';

-- Grant privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce_system.* TO 'ecommerce_user'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- ============================================================
-- Verification Queries
-- ============================================================

-- Count records in each table
SELECT 'inventory' AS table_name, COUNT(*) AS record_count FROM inventory
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'pricing_rules', COUNT(*) FROM pricing_rules
UNION ALL
SELECT 'tax_rates', COUNT(*) FROM tax_rates;

-- Display sample data
SELECT '--- INVENTORY ---' AS info;
SELECT product_id, product_name, quantity_available, unit_price FROM inventory LIMIT 5;

SELECT '--- CUSTOMERS ---' AS info;
SELECT customer_id, name, email, loyalty_points FROM customers;

SELECT '--- PRICING RULES ---' AS info;
SELECT pr.rule_id, i.product_name, pr.min_quantity, pr.discount_percentage 
FROM pricing_rules pr
JOIN inventory i ON pr.product_id = i.product_id
ORDER BY pr.product_id, pr.min_quantity;

SELECT '--- TAX RATES ---' AS info;
SELECT * FROM tax_rates;

-- ============================================================
-- Success Message
-- ============================================================
SELECT '
✅ DATABASE SETUP COMPLETED SUCCESSFULLY!

Tables created:
  ✓ inventory
  ✓ customers
  ✓ orders
  ✓ order_items
  ✓ pricing_rules
  ✓ tax_rates
  ✓ notification_log

Sample data inserted:
  ✓ 10 products
  ✓ 5 customers
  ✓ 10 pricing rules
  ✓ 6 tax rates

User created:
  ✓ ecommerce_user@localhost

You can now start the microservices!
' AS message;

select * from notification_log;



