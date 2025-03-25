/*
===============================================================================
Stored Procedure: load_silver (Simple Version with Filtered order_payments using CTE)
===============================================================================
Procedure Purpose:
    This stored procedure loads data from 'bronze' to 'silver' with minimal processing.
    - Basic load without complex transformations.
    - Filters order_payments to ensure payment discrepancy is within threshold (<= 1.0) using CTE.
    - Use quality checks afterward to identify and fix issues iteratively.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql AS
$$
DECLARE 
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    total_time INTERVAL;
BEGIN
    -- Record start time
    start_time := NOW();
    RAISE NOTICE 'Loading data into silver schema started at %', start_time;
    
    -- Truncate tables in silver schema
    TRUNCATE TABLE 
        silver.orders,
        silver.order_items,
        silver.order_payments,
        silver.order_reviews,
        silver.products,
        silver.sellers,
        silver.customers,
        silver.geolocation,
        silver.product_category_name_translation
    RESTART IDENTITY;
    
    RAISE NOTICE 'Silver tables truncated successfully.';
    
    -- Load silver.orders 
    INSERT INTO silver.orders
    SELECT o.* 
    FROM bronze.orders o
    INNER JOIN bronze.order_items oi ON o.order_id = oi.order_id 
    WHERE o.order_id IS NOT NULL 
        AND (o.order_status != 'delivered' OR o.order_delivered_customer_date IS NOT NULL)
    GROUP BY o.order_id, o.customer_id, o.order_status, o.order_purchase_timestamp, o.order_approved_at, 
             o.order_delivered_carrier_date, o.order_delivered_customer_date, 
             o.order_estimated_delivery_date;
    RAISE NOTICE 'silver.orders loaded.';
    
    -- Load silver.order_items (Fixed: Explicit column list)
    WITH ranked_items AS (
        SELECT 
            oi.order_id,
            CAST(oi.order_item_id AS integer) AS order_item_id,
            oi.product_id,
            oi.seller_id,
            oi.shipping_limit_date,
            oi.price,
            oi.freight_value,
            ROW_NUMBER() OVER (PARTITION BY oi.order_id ORDER BY CAST(oi.order_item_id AS integer) DESC) AS rn
        FROM bronze.order_items oi
        RIGHT JOIN silver.orders o ON oi.order_id = o.order_id
    )
    INSERT INTO silver.order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
    SELECT 
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM ranked_items
    WHERE rn = 1;
    RAISE NOTICE 'silver.order_items loaded.';
    
    -- Load silver.order_payments with discrepancy filter
    WITH ranked_payments AS (
        SELECT 
            op.order_id,
            op.payment_sequential,
            op.payment_type,
            op.payment_installments,
            SUM(op.payment_value) OVER (PARTITION BY op.order_id) AS total_payment_value,
            ROW_NUMBER() OVER (PARTITION BY op.order_id ORDER BY op.payment_sequential DESC) AS rn
        FROM bronze.order_payments op
        RIGHT JOIN silver.orders o ON op.order_id = o.order_id
    )
    INSERT INTO silver.order_payments
    SELECT 
        rp.order_id,
        rp.payment_sequential,
        rp.payment_type,
        rp.payment_installments,
        rp.total_payment_value AS payment_value
    FROM ranked_payments rp
    INNER JOIN silver.order_items oi ON rp.order_id = oi.order_id
    WHERE rp.rn = 1
        AND ABS(rp.total_payment_value - (oi.order_item_id * (oi.price + oi.freight_value))) <= 1.0;
    RAISE NOTICE 'silver.order_payments loaded.';
    
    -- Load silver.order_reviews
    WITH review_cte AS (
        SELECT 
            r.*, 
            ROW_NUMBER() OVER (PARTITION BY r.review_id ORDER BY r.order_id DESC) AS rn
        FROM bronze.order_reviews r
        RIGHT JOIN silver.orders o ON r.order_id = o.order_id
    )  
    INSERT INTO silver.order_reviews
    SELECT 
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM review_cte
    WHERE rn = 1 AND review_id IS NOT NULL;
    RAISE NOTICE 'silver.order_reviews loaded.';
    
    -- Load silver.products
	INSERT INTO silver.products
    SELECT DISTINCT p.* 
    FROM bronze.products p
    INNER JOIN silver.order_items oi ON p.product_id = oi.product_id
    WHERE p.product_id IS NOT NULL;
    RAISE NOTICE 'silver.products loaded.';
    
    -- Load silver.sellers
    INSERT INTO silver.sellers
    SELECT DISTINCT s.* 
    FROM bronze.sellers s
	INNER JOIN silver.order_items oi ON s.seller_id = oi.seller_id
    WHERE s.seller_id IS NOT NULL;
    RAISE NOTICE 'silver.sellers loaded.';
    
    -- Load silver.customers
    INSERT INTO silver.customers
    SELECT DISTINCT c.* 
    FROM bronze.customers c 
	INNER JOIN silver.orders o ON c.customer_id = o.customer_id
    WHERE c.customer_id IS NOT NULL;
    RAISE NOTICE 'silver.customers loaded.';
    
    -- Load silver.geolocation
    WITH cleaned_geolocation AS (
        SELECT 
            geolocation_zip_code_prefix, 
            geolocation_lat, 
            geolocation_lng, 
            INITCAP(
                REGEXP_REPLACE(
                    UNACCENT(TRIM(geolocation_city)), 
                    '[^a-zA-ZÀ-ÿ ]', '', 'g'
                )
            ) AS geolocation_city, 
            CASE TRIM(geolocation_state)
                WHEN 'AC' THEN 'Acre'
                WHEN 'AL' THEN 'Alagoas'
                WHEN 'AP' THEN 'Amapa'
                WHEN 'AM' THEN 'Amazonas'
                WHEN 'BA' THEN 'Bahia'
                WHEN 'CE' THEN 'Ceara'
                WHEN 'DF' THEN 'Federal District'
                WHEN 'ES' THEN 'Espirito Santo'
                WHEN 'GO' THEN 'Goias'
                WHEN 'MA' THEN 'Maranhao'
                WHEN 'MT' THEN 'Mato Grosso'
                WHEN 'MS' THEN 'Mato Grosso do Sul'
                WHEN 'MG' THEN 'Minas Gerais'
                WHEN 'PA' THEN 'Para'
                WHEN 'PB' THEN 'Paraiba'
                WHEN 'PR' THEN 'Parana'
                WHEN 'PE' THEN 'Pernambuco'
                WHEN 'PI' THEN 'Piaui'
                WHEN 'RJ' THEN 'Rio de Janeiro'
                WHEN 'RN' THEN 'Rio Grande do Norte'
                WHEN 'RS' THEN 'Rio Grande do Sul'
                WHEN 'RO' THEN 'Rondonia'
                WHEN 'RR' THEN 'Roraima'
                WHEN 'SC' THEN 'Santa Catarina'
                WHEN 'SP' THEN 'Sao Paulo'
                WHEN 'SE' THEN 'Sergipe'
                WHEN 'TO' THEN 'Tocantins'
            END AS geolocation_state,
            ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY geolocation_lat, geolocation_lng) AS rn
        FROM bronze.geolocation
        WHERE geolocation_zip_code_prefix IS NOT NULL
    )
    INSERT INTO silver.geolocation
    SELECT 
        geolocation_zip_code_prefix, 
        geolocation_lat, 
        geolocation_lng, 
        geolocation_city, 
        geolocation_state
    FROM cleaned_geolocation
    WHERE rn = 1;
    RAISE NOTICE 'silver.geolocation loaded.';
    
    -- Load silver.product_category_name_translation
    INSERT INTO silver.product_category_name_translation
    SELECT DISTINCT t.* 
    FROM bronze.product_category_name_translation t
	INNER JOIN silver.products p ON t.product_category_name = p.product_category_name
    WHERE t.product_category_name IS NOT NULL;
    RAISE NOTICE 'silver.product_category_name_translation loaded.';

    -- Record completion time
    end_time := NOW();
    total_time := end_time - start_time;
    
    RAISE NOTICE 'Data loading into silver schema completed at %', end_time;
    RAISE NOTICE 'Total execution time: %', total_time;
END;
$$;

-- Execute the procedure
CALL silver.load_silver();