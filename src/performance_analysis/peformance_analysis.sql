SELECT * FROM gold.fact_orders; 

-- 1. Doanh thu thay đổi như thế nào theo thời gian, và đâu là các tháng cao điểm cho doanh số bán hàng?
SELECT EXTRACT(MONTH FROM order_timestamp) AS "month", 
       SUM(unit_price + freight_value) AS revenue
FROM gold.fact_orders
GROUP BY EXTRACT(MONTH FROM order_timestamp)
ORDER BY revenue DESC;

-- 2. Danh mục sản phẩm nào đóng góp nhiều nhất vào tổng doanh thu, và tại sao?
SELECT dp.category_name_english, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.category_name_english
ORDER BY revenue DESC
LIMIT 1;

-- 3. Sản phẩm nào bán chạy nhất (theo số lượng và doanh thu) trong từng danh mục?
-- Theo số lượng
SELECT dp.category_name_english, dp.product_id, 
       COUNT(*) AS quantity_sold
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.category_name_english, dp.product_id
ORDER BY dp.category_name_english, quantity_sold DESC;

-- Theo doanh thu
SELECT dp.category_name_english, dp.product_id, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.category_name_english, dp.product_id
ORDER BY dp.category_name_english, revenue DESC;


-- 4. Có sự khác biệt nào về doanh thu giữa các khu vực địa lý (ví dụ: Sao Paulo so với các thành phố khác)?
SELECT dc.city, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_customers dc ON fo.customer_key = dc.customer_key
GROUP BY dc.city
ORDER BY revenue DESC;

-- 5. Phương thức thanh toán nào được khách hàng ưa chuộng nhất, và điều này ảnh hưởng đến giá trị đơn hàng trung bình (AOV) như thế nào?
-- Phương thức thanh toán ưa chuộng
SELECT dp.payment_type, 
       COUNT(*) AS transaction_count
FROM gold.fact_orders fo
JOIN gold.dim_payments dp ON fo.payment_key = dp.payment_key
GROUP BY dp.payment_type
ORDER BY transaction_count DESC;

-- AOV theo phương thức thanh toán
SELECT dp.payment_type, 
       AVG(fo.unit_price + fo.freight_value) AS aov
FROM gold.fact_orders fo
JOIN gold.dim_payments dp ON fo.payment_key = dp.payment_key
GROUP BY dp.payment_type
ORDER BY aov DESC;

-- 6. Tỷ lệ khách hàng quay lại khác nhau như thế nào giữa các khu vực địa lý?
SELECT dc.city, 
       COUNT(DISTINCT fo.customer_key) AS returning_customers
FROM gold.fact_orders fo
JOIN gold.dim_customers dc ON fo.customer_key = dc.customer_key
GROUP BY dc.city
HAVING COUNT(DISTINCT fo.order_id) > 1
ORDER BY returning_customers DESC;

-- 7. Sản phẩm nào thường được mua cùng nhau, và làm thế nào để tận dụng điều này cho chiến lược cross-selling?
SELECT p1.product_id AS product_1, p2.product_id AS product_2, 
       COUNT(*) AS frequency
FROM gold.fact_orders fo1
JOIN gold.fact_orders fo2 ON fo1.order_id = fo2.order_id AND fo1.product_key != fo2.product_key
JOIN gold.dim_products p1 ON fo1.product_key = p1.product_key
JOIN gold.dim_products p2 ON fo2.product_key = p2.product_key
GROUP BY p1.product_id, p2.product_id
ORDER BY frequency DESC;


-- 8. Sản phẩm nào có tỷ lệ đánh giá thấp, và điều này ảnh hưởng đến doanh thu như thế nào?
SELECT dp.category_name_english, 
       AVG(dr.review_score) AS avg_rating, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
JOIN gold.dim_reviews dr ON fo.review_key = dr.review_key
GROUP BY dp.category_name_english
HAVING AVG(dr.review_score) < 3
ORDER BY avg_rating ASC;


-- 9. Người bán nào có hiệu suất tốt nhất dựa trên doanh thu và đánh giá khách hàng?
SELECT ds.seller_id, ds.city, 
       SUM(fo.unit_price + fo.freight_value) AS revenue, 
       AVG(dr.review_score) AS avg_rating
FROM gold.fact_orders fo
JOIN gold.dim_sellers ds ON fo.seller_key = ds.seller_key
JOIN gold.dim_reviews dr ON fo.review_key = dr.review_key
GROUP BY ds.seller_id, ds.city
ORDER BY revenue DESC, avg_rating DESC
LIMIT 1;


-- 10. Làm thế nào để tối ưu hóa danh mục sản phẩm để tăng trưởng doanh thu?
SELECT dp.category_name_english, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.category_name_english
ORDER BY revenue DESC;


-- 11. Khách hàng thường mua sắm vào thời điểm nào trong ngày hoặc tuần, và điều này có thể được sử dụng để tối ưu hóa chiến dịch marketing không?
SELECT EXTRACT(HOUR FROM order_timestamp) AS hour, 
       EXTRACT(DOW FROM order_timestamp) AS day_of_week, 
       COUNT(*) AS order_count
FROM gold.fact_orders
GROUP BY EXTRACT(HOUR FROM order_timestamp), EXTRACT(DOW FROM order_timestamp)
ORDER BY order_count DESC;


-- 12. Có mối quan hệ nào giữa giá sản phẩm và số lượng bán ra không?
SELECT dp.product_id, 
       AVG(fo.unit_price) AS avg_price, 
       COUNT(*) AS quantity_sold
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.product_id
ORDER BY quantity_sold DESC;


-- 13. Sản phẩm nào có doanh thu tăng trưởng nhanh nhất trong các tháng gần đây?
SELECT dp.category_name_english, 
       EXTRACT(MONTH FROM fo.order_timestamp) AS month, 
       SUM(fo.unit_price + fo.freight_value) AS revenue
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.category_name_english, EXTRACT(MONTH FROM fo.order_timestamp)
ORDER BY month, revenue DESC;


-- 14. Khách hàng từ khu vực nào có xu hướng mua các sản phẩm đắt tiền hơn?
SELECT dc.city, 
       AVG(fo.unit_price + fo.freight_value) AS avg_order_value
FROM gold.fact_orders fo
JOIN gold.dim_customers dc ON fo.customer_key = dc.customer_key
GROUP BY dc.city
ORDER BY avg_order_value DESC;


-- 15. Các chiến dịch giảm giá hoặc khuyến mãi ảnh hưởng đến doanh thu và hành vi khách hàng như thế nào?
SELECT EXTRACT(MONTH FROM order_timestamp) AS month, 
       SUM(unit_price + freight_value) AS revenue, 
       COUNT(DISTINCT customer_key) AS new_customers
FROM gold.fact_orders
GROUP BY EXTRACT(MONTH FROM order_timestamp)
ORDER BY revenue DESC;


-- 16. Người bán nào có tỷ lệ đánh giá thấp, và họ cần cải thiện ở điểm nào để tăng doanh số?
SELECT ds.seller_id, ds.city, 
       AVG(dr.review_score) AS avg_rating
FROM gold.fact_orders fo
JOIN gold.dim_sellers ds ON fo.seller_key = ds.seller_key
JOIN gold.dim_reviews dr ON fo.review_key = dr.review_key
GROUP BY ds.seller_id, ds.city
HAVING AVG(dr.review_score) < 3
ORDER BY avg_rating ASC;

-- 17. Sản phẩm nào có tỷ lệ hủy đơn hàng cao nhất, và nguyên nhân là gì?
SELECT dp.category_name_english, 
       COUNT(*) AS canceled_orders
FROM gold.fact_orders fo
JOIN gold.dim_products dp ON fo.product_key = dp.product_key
WHERE fo.order_status = 'canceled'
GROUP BY dp.category_name_english
ORDER BY canceled_orders DESC;

