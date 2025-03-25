/*
===============================================================================
Quality Checks for Olist Silver Layer (Extended Version)
===============================================================================
Script Purpose:
    This script performs extended quality checks on the Olist 'silver' layer to ensure:
    - No NULLs or duplicates in primary keys.
    - No unwanted spaces in string fields.
    - Data standardization and consistency.
    - Valid date ranges and logical date orders.
    - Data consistency between related fields and tables.

Usage Notes:
    - Run these checks after loading data into the Silver Layer.
    - Investigate and resolve any discrepancies identified.
    - Added checks include cross-table relationships and outlier detection.
*/




-- ====================================================================
-- Checking 'silver.orders'
-- ====================================================================
SELECT COUNT(*) FROM bronze.orders;
SELECT COUNT(*) FROM silver.orders;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No results 
SELECT 
    order_id,
    COUNT(*) 
FROM silver.orders
GROUP BY order_id
HAVING COUNT(*) > 1 OR order_id IS NULL;

-- Check for Invalid Date Orders (e.g., Order Date > Delivery Date)
-- Expectation: No Results
SELECT 
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM silver.orders
WHERE order_purchase_timestamp > order_delivered_customer_date;

-- Check for Missing Timestamps in Delivered Orders
-- Expectation: No results
SELECT 
    order_id,
    order_status,
    order_delivered_customer_date
FROM silver.orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- Check Data Standardization & Consistency
SELECT DISTINCT 
    order_status 
FROM silver.orders;

-- Check for Orders Without Items 
-- Expectation: No results
SELECT 
    o.order_id
FROM silver.orders o
LEFT JOIN silver.order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;




-- ====================================================================
-- Checking 'silver.order_items'
-- ====================================================================
SELECT COUNT(*) FROM bronze.order_items;
SELECT COUNT(*) FROM silver.order_items;

-- Check for NULLs or Duplicates in Composite Primary Key (order_id, order_item_id)
-- Expectation: No Results
SELECT 
    order_id, 
    COUNT(*) 
FROM silver.order_items
GROUP BY order_id
HAVING COUNT(*) > 1 OR order_id IS NULL;
	
-- Check for Negative or NULL Prices/Freight Values
-- Expectation: No Results
SELECT 
    order_id,
    order_item_id,
    price,
    freight_value
FROM silver.order_items
WHERE price < 0 OR freight_value < 0 OR price IS NULL OR freight_value IS NULL;


-- Check for Orphan Order Items (No Matching Order)
-- Expectation: No Results
SELECT 
    oi.order_id
FROM silver.order_items oi
LEFT JOIN silver.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;




-- ====================================================================
-- Checking 'silver.order_payments'
-- ====================================================================
SELECT COUNT(*) FROM bronze.order_payments;
SELECT COUNT(*) FROM silver.order_payments;

-- Check for NULLs or Duplicates in Composite Primary Key (order_id, payment_sequential)
-- Expectation: No Results
SELECT 
    order_id,
    COUNT(*) 
FROM silver.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1 OR order_id IS NULL;

-- Check for Negative or NULL Payment Values
-- Expectation: No Results
SELECT 
    order_id,
    payment_value
FROM silver.order_payments
WHERE payment_value < 0 OR payment_value IS NULL;

-- Check Data Standardization & Consistency
SELECT DISTINCT 
    payment_type 
FROM silver.order_payments;

-- Check for Orphan Order Payment (No Matching Order)
-- Expectation: No Results
select * from silver.order_payments; 
SELECT 
    op.order_id
FROM silver.order_payments op
LEFT JOIN silver.orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;



-- Check Payment Total vs. Order Items Total
-- Expectation: Minimal Discrepancies (Allow Small Rounding Errors)
SELECT 
    o.order_id,
    SUM(op.payment_value) AS total_payment,
    SUM(oi.order_item_id * (oi.price + oi.freight_value)) AS total_items_cost,
    ABS(SUM(op.payment_value) - SUM(oi.order_item_id * (oi.price + oi.freight_value))) AS discrepancy
FROM silver.orders o
INNER JOIN silver.order_payments op ON o.order_id = op.order_id
INNER JOIN silver.order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id
HAVING ABS(SUM(op.payment_value) - SUM(oi.order_item_id * (oi.price + oi.freight_value))) > 1.0 -- Threshold for investigation
ORDER BY discrepancy DESC;


-- ====================================================================
-- Checking 'silver.order_reviews'
-- ====================================================================
SELECT COUNT(*) FROM bronze.order_reviews;
SELECT * FROM silver.order_reviews
WHERE order_id like '02e0b68852217f5715fb9cc885829454';

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
	review_id
FROM silver.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1 OR review_id IS NULL;

-- Check for Invalid Review Scores (e.g., outside 1-5 range)
-- Expectation: No Results
SELECT 
    review_id,
    review_score
FROM silver.order_reviews
WHERE review_score < 1 OR review_score > 5 OR review_score IS NULL;

-- Check for Invalid Date Orders (Review Creation > Answer)
-- Expectation: No Results
SELECT 
    review_id,
    review_creation_date,
    review_answer_timestamp
FROM silver.order_reviews
WHERE review_creation_date > review_answer_timestamp;

-- Check for Orphan Reviews (No Matching Order)
-- Expectation: No Results
SELECT 
    r.review_id,
    r.order_id
FROM silver.order_reviews r
LEFT JOIN silver.orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;



	
-- ====================================================================
-- Checking 'silver.products'
-- ====================================================================
SELECT COUNT(*) FROM bronze.products;
SELECT COUNT(*) FROM silver.products;
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    product_id,
    COUNT(*) 
FROM silver.products
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

-- Check for Unwanted Spaces in Product Category Name
-- Expectation: No Results
SELECT 
    product_category_name 
FROM silver.products
WHERE product_category_name != TRIM(product_category_name);

-- Check for Products Not Linked to Order Items
-- Expectation: Investigate Unused Products
SELECT 
    p.product_id
FROM silver.products p
LEFT JOIN silver.order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;




-- ====================================================================
-- Checking 'silver.sellers'
-- ====================================================================
SELECT COUNT(*) FROM bronze.sellers;
SELECT COUNT(*) FROM silver.sellers;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    seller_id,
    COUNT(*) 
FROM silver.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1 OR seller_id IS NULL;

-- Check for Unwanted Spaces in Seller City/State
-- Expectation: No Results
SELECT 
    seller_id,
    seller_city,
    seller_state
FROM silver.sellers
WHERE seller_city != TRIM(seller_city) OR seller_state != TRIM(seller_state);

-- Check for Sellers Without Sales
-- Expectation: Investigate Inactive Sellers
SELECT 
    s.seller_id
FROM silver.sellers s
LEFT JOIN silver.order_items oi ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;




-- ====================================================================
-- Checking 'silver.customers'
-- ====================================================================
SELECT COUNT(*) FROM bronze.customers;
SELECT COUNT(*) FROM silver.customers;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    customer_id,
    COUNT(*) 
FROM silver.customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Check for Unwanted Spaces in Customer City/State
-- Expectation: No Results
SELECT 
    customer_id,
    customer_city,
    customer_state
FROM silver.customers
WHERE customer_city != TRIM(customer_city) OR customer_state != TRIM(customer_state);

-- Check for Customers Without Orders
-- Expectation: Investigate Inactive Customers
SELECT 
    c.customer_id
FROM silver.customers c
LEFT JOIN silver.orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;




-- ====================================================================
-- Checking 'silver.geolocation'
-- ====================================================================
SELECT COUNT(*) FROM bronze.geolocation;
SELECT COUNT(*) FROM silver.geolocation;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT geolocation_zip_code_prefix, COUNT(*) 
FROM silver.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1 OR geolocation_zip_code_prefix IS NULL; 

-- Check for Unwanted Spaces in City/State
-- Expectation: No Results
SELECT 
    geolocation_city,
    geolocation_state
FROM bronze.geolocation
WHERE geolocation_city != TRIM(geolocation_city) OR geolocation_state != TRIM(geolocation_state);


-- ====================================================================
-- Checking 'silver.product_category_name_translation'
-- ====================================================================
SELECT COUNT(*) FROM bronze.product_category_name_translation;
SELECT COUNT(*) FROM silver.product_category_name_translation;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    product_category_name,
    COUNT(*) 
FROM silver.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1 OR product_category_name IS NULL;

-- Check for Unwanted Spaces in Names
-- Expectation: No Results
SELECT 
    product_category_name,
    product_category_name_english
FROM silver.product_category_name_translation
WHERE product_category_name != TRIM(product_category_name) 
   OR product_category_name_english != TRIM(product_category_name_english);

-- Check for Missing Translations in Products Table
-- Expectation: No Results
SELECT DISTINCT t.product_category_name
FROM silver.product_category_name_translation t
LEFT JOIN silver.products p ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL;