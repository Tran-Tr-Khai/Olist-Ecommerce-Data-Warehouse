/*
===============================================================================
Quality Checks for Gold Layer
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables (dim_customers, dim_products, dim_sellers, dim_payments, dim_reviews).
    - Referential integrity between fact_orders and dimension tables.
    - Validation of relationships in the Star Schema for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
    - No results returned indicates the check passed successfully.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results (all customer_key values are unique)
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check for NULL Customer Keys
-- Expectation: No results (no NULL customer_key values)
SELECT 
    customer_id,
    customer_key
FROM gold.dim_customers
WHERE customer_key IS NULL;

-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results (all product_key values are unique)
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check for NULL Product Keys
-- Expectation: No results (no NULL product_key values)
SELECT 
    product_id,
    product_key
FROM gold.dim_products
WHERE product_key IS NULL;

-- ====================================================================
-- Checking 'gold.dim_sellers'
-- ====================================================================
-- Check for Uniqueness of Seller Key in gold.dim_sellers
-- Expectation: No results (all seller_key values are unique)
SELECT 
    seller_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_sellers
GROUP BY seller_key
HAVING COUNT(*) > 1;

-- Check for NULL Seller Keys
-- Expectation: No results (no NULL seller_key values)
SELECT 
    seller_id,
    seller_key
FROM gold.dim_sellers
WHERE seller_key IS NULL;

-- ====================================================================
-- Checking 'gold.dim_payments'
-- ====================================================================
-- Check for Uniqueness of Payment Key in gold.dim_payments
-- Expectation: No results (all payment_key values are unique)
SELECT 
    payment_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_payments
GROUP BY payment_key
HAVING COUNT(*) > 1;

-- Check for NULL Payment Keys
-- Expectation: No results (no NULL payment_key values)
SELECT 
    order_id,
    payment_key
FROM gold.dim_payments
WHERE payment_key IS NULL;

-- ====================================================================
-- Checking 'gold.dim_reviews'
-- ====================================================================
-- Check for Uniqueness of Review Key in gold.dim_reviews
-- Expectation: No results (all review_key values are unique)
SELECT 
    review_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_reviews
GROUP BY review_key
HAVING COUNT(*) > 1;

-- Check for NULL Review Keys
-- Expectation: No results (no NULL review_key values)
SELECT 
    order_id,
    review_key
FROM gold.dim_reviews
WHERE review_key IS NULL;

-- ====================================================================
-- Checking 'gold.fact_orders'
-- ====================================================================
SELECT 
    order_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Check for NULL Foreign Keys in fact_orders
-- Expectation: Investigate if any critical keys are NULL (e.g., customer_key, product_key)
SELECT 
    order_id,
    customer_key,
    product_key,
    seller_key,
    payment_key,
    review_key
FROM gold.fact_orders
WHERE customer_key IS NULL 
   OR product_key IS NULL 
   OR seller_key IS NULL

