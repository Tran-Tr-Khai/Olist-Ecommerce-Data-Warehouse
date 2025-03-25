/*
===============================================================================
DDL Script: Create Gold Views for Star Schema
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in a Star Schema format:
    - Fact table: fact_orders (combines silver.orders and silver.order_items).
    - Dimension tables: dim_customers, dim_products, dim_sellers, dim_payments, dim_reviews.

    The design integrates orders and items into a fact table, with flat dimensions for additional context.

Usage:
    - These views can be queried directly for reporting and analytics.
===============================================================================
*/

-- Create gold schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop all dependent views with CASCADE to avoid dependency errors
DROP VIEW IF EXISTS gold.fact_orders CASCADE;
DROP VIEW IF EXISTS gold.dim_customers CASCADE;
DROP VIEW IF EXISTS gold.dim_products CASCADE;
DROP VIEW IF EXISTS gold.dim_sellers CASCADE;
DROP VIEW IF EXISTS gold.dim_payments CASCADE;
DROP VIEW IF EXISTS gold.dim_reviews CASCADE;
-- =============================================================================
-- Create Dimension: gold.dim_customers
-- Purpose: Provides customer details for sales analysis
-- =============================================================================
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key, -- Surrogate key
    c.customer_id AS customer_id,
    c.customer_unique_id AS customer_unique_id,
    c.customer_zip_code_prefix AS zip_code_prefix,
    g.geolocation_lat AS lat,
    g.geolocation_lng AS lng,
    g.geolocation_city AS city,
    g.geolocation_state AS state
FROM silver.customers c
LEFT JOIN silver.geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;
COMMENT ON VIEW gold.dim_customers IS 'Dimension table for customer details with geolocation';

-- =============================================================================
-- Create Dimension: gold.dim_products
-- Purpose: Provides product details with translated category names
-- =============================================================================
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key, -- Surrogate key
    p.product_id AS product_id,
    p.product_category_name AS category_name,
    t.product_category_name_english AS category_name_english,
    p.product_name_length AS name_length,
    p.product_description_length AS description_length,
    p.product_photos_qty AS photos_qty,
    p.product_weight_g AS weight_g,
    p.product_length_cm AS length_cm,
    p.product_height_cm AS height_cm,
    p.product_width_cm AS width_cm
FROM silver.products p
LEFT JOIN silver.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;
COMMENT ON VIEW gold.dim_products IS 'Dimension table for product details with English translations';

-- =============================================================================
-- Create Dimension: gold.dim_sellers
-- Purpose: Provides seller details for sales analysis
-- =============================================================================
CREATE VIEW gold.dim_sellers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY s.seller_id) AS seller_key, -- Surrogate key
    s.seller_id AS seller_id,
    s.seller_zip_code_prefix AS zip_code_prefix,
    g.geolocation_lat AS lat,
    g.geolocation_lng AS lng,
    g.geolocation_city AS city,
    g.geolocation_state AS state
FROM silver.sellers s
LEFT JOIN silver.geolocation g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;
COMMENT ON VIEW gold.dim_sellers IS 'Dimension table for seller details with geolocation';

-- =============================================================================
-- Create Dimension: gold.dim_payments
-- Purpose: Provides payment details linked to orders
-- =============================================================================
CREATE VIEW gold.dim_payments AS
SELECT
    ROW_NUMBER() OVER (ORDER BY op.order_id, op.payment_sequential) AS payment_key, -- Surrogate key, unique by order_id and payment_sequential
    op.order_id AS order_id,
    op.payment_sequential AS payment_sequential,
    op.payment_type AS payment_type,
    op.payment_installments AS payment_installments,
    op.payment_value AS payment_value
FROM silver.order_payments op;
COMMENT ON VIEW gold.dim_payments IS 'Dimension table for payment details linked to orders';

-- =============================================================================
-- Create Dimension: gold.dim_reviews
-- Purpose: Provides review details linked to orders
-- =============================================================================
CREATE OR REPLACE VIEW gold.dim_reviews AS
SELECT
    ROW_NUMBER() OVER (ORDER BY review_id) AS review_key,
    order_id AS order_id,
    review_id AS review_id,
    review_score AS review_score,
    review_comment_title AS review_comment_title,
    review_comment_message AS review_comment_message,
    review_creation_date AS review_creation_date,
    review_answer_timestamp AS review_answer_timestamp
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date) AS rn
    FROM silver.order_reviews
) 
WHERE rn = 1;
COMMENT ON VIEW gold.dim_reviews IS 'Dimension table for review details, one review per order';

-- =============================================================================
-- Create Fact Table: gold.fact_orders
-- Purpose: Combines orders and order_items data with links to dimensions
-- =============================================================================
CREATE VIEW gold.fact_orders AS
SELECT
    o.order_id AS order_id,
    dc.customer_key AS customer_key,
    p.product_key AS product_key,
    ds.seller_key AS seller_key,
    dp.payment_key AS payment_key,
    dr.review_key AS review_key,
    o.order_status AS order_status,
    o.order_purchase_timestamp AS order_timestamp,
    o.order_approved_at AS approved_timestamp,
    o.order_delivered_carrier_date AS carrier_delivery_timestamp,
    o.order_delivered_customer_date AS customer_delivery_timestamp,
    o.order_estimated_delivery_date AS estimated_delivery_timestamp,
    oi.order_item_id AS item_sequence, -- Sequence of items in the order
    oi.shipping_limit_date AS shipping_limit_date,
    oi.price AS unit_price,
    oi.freight_value AS freight_value
FROM silver.orders o
INNER JOIN silver.order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN gold.dim_customers dc
    ON o.customer_id = dc.customer_id
LEFT JOIN gold.dim_products p
    ON oi.product_id = p.product_id
LEFT JOIN gold.dim_sellers ds
    ON oi.seller_id = ds.seller_id
LEFT JOIN gold.dim_payments dp
    ON o.order_id = dp.order_id
LEFT JOIN gold.dim_reviews dr
    ON o.order_id = dr.order_id;
COMMENT ON VIEW gold.fact_orders IS 'Fact table combining orders and order_items with links to all dimensions';


SELECT * FROM gold.fact_orders;