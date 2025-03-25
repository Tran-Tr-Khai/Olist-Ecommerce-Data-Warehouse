/*
===============================================================================
Stored Procedure: load_bronze
===============================================================================
Procedure Purpose:
    This stored procedure loads data from CSV files into the 'bronze' schema.
    It performs the following steps:
    1. Truncate tables to remove old data.
    2. Load new data using the COPY command.
    3. Log timestamps for each step.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE 
    start_time TIMESTAMP;
	end_time TIMESTAMP;
	total_time INTERVAL;
BEGIN
    -- Record start time
    start_time := NOW();
    RAISE NOTICE 'Loading data into bronze schema started at %', start_time;

    -- Truncate tables to remove old data
    TRUNCATE TABLE 
        bronze.orders,
        bronze.order_items,
        bronze.order_payments,
        bronze.order_reviews,
        bronze.products,
        bronze.sellers,
        bronze.customers,
        bronze.geolocation,
        bronze.product_category_name_translation
    RESTART IDENTITY;

    RAISE NOTICE 'Tables truncated successfully.';

    -- Load data from CSV files
    COPY bronze.orders FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\orders.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Orders table loaded.';

    COPY bronze.order_items FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\order_items.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Order_items table loaded.';

    COPY bronze.order_payments FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\order_payments.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Order_payments table loaded.';

    COPY bronze.order_reviews FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\order_reviews.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Order_reviews table loaded.';

    COPY bronze.products FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\products.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Products table loaded.';

    COPY bronze.sellers FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\sellers.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Sellers table loaded.';

    COPY bronze.customers FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\customers.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Customers table loaded.';

    COPY bronze.geolocation FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\geolocation.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Geolocation table loaded.';

    COPY bronze.product_category_name_translation FROM 'C:\Program Files\PostgreSQL\17\data\olist_raw_data\product_category_name_translation.csv' DELIMITER ',' CSV HEADER;
    RAISE NOTICE 'Product category name translation table loaded.';

    -- Record completion time
    end_time := NOW();
    total_time := end_time - start_time;
    
    RAISE NOTICE 'Data loading completed at %', end_time;
    RAISE NOTICE 'Total execution time: %', total_time;
END;
$$;


CALL bronze.load_bronze()
