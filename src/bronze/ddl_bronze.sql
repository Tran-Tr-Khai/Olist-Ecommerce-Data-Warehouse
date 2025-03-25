/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

-- Create schema if not exists 
CREATE SCHEMA IF NOT EXISTS bronze; 
 
-- Orders table
DROP TABLE IF EXISTS bronze.orders;
CREATE TABLE bronze.orders (
    order_id VARCHAR(50), 
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Order_items table
DROP TABLE IF EXISTS bronze.order_items;
CREATE TABLE bronze.order_items (
    order_id VARCHAR(50), 
    order_item_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
);

-- Order_payments table
DROP TABLE IF EXISTS bronze.order_payments;
CREATE TABLE bronze.order_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value DECIMAL(10, 2)
);

-- Order_reviews table
DROP TABLE IF EXISTS bronze.order_reviews;
CREATE TABLE bronze.order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- Products table
DROP TABLE IF EXISTS bronze.products;
CREATE TABLE bronze.products (
    product_id VARCHAR(50), 
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- Sellers table
DROP TABLE IF EXISTS bronze.sellers;
CREATE TABLE bronze.sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(8),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- Customers table
DROP TABLE IF EXISTS bronze.customers;
CREATE TABLE bronze.customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(8),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- Geolocation table
DROP TABLE IF EXISTS bronze.geolocation;
CREATE TABLE bronze.geolocation (
    geolocation_zip_code_prefix VARCHAR(8),
    geolocation_lat DECIMAL(9, 6),
    geolocation_lng DECIMAL(9, 6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- Product category name translation table
DROP TABLE IF EXISTS bronze.product_category_name_translation;
CREATE TABLE bronze.product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
