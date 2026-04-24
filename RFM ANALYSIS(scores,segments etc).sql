-- SET @analysis_date = CURRENT_DATE;
-- SELECT @analysis_date;
-- CREATE TABLE customer_rfm_metricsss AS
-- SELECT 
--     c.customer_id,
--     c.first_name,
--     c.email,
--     c.country,
--     c.age_group,
--     
--     DATEDIFF(@analysis_date, MAX(o.order_date)) as recency_days,
--     COUNT(DISTINCT o.order_id) as frequency_count,
--     SUM(o.order_total) as monetary_value,
--     
--     AVG(o.order_total) as avg_order_value,
--     MIN(o.order_date) as first_purchase_date,
--     MAX(o.order_date) as last_purchase_date,
--     DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_lifespan_days

-- FROM customers c
-- LEFT JOIN orders o 
-- ON c.customer_id = o.customer_id

-- GROUP BY 
--     c.customer_id, 
--     c.first_name, 
--     c.email, 
--     c.country, 
--     c.age_group

-- HAVING COUNT(DISTINCT o.order_id) > 0;

-- SELECT * FROM customer_rfm_metricsss LIMIT 10;

-- CREATE TABLE customer_rfm_scores AS
-- SELECT *,
--     
--     CASE 
--         WHEN recency_days <= 30 THEN 5
--         WHEN recency_days <= 60 THEN 4
--         WHEN recency_days <= 90 THEN 3
--         WHEN recency_days <= 120 THEN 2
--         ELSE 1
--     END as R_score,

--     CASE 
--         WHEN frequency_count >= 10 THEN 5
--         WHEN frequency_count >= 7 THEN 4
--         WHEN frequency_count >= 5 THEN 3
--         WHEN frequency_count >= 3 THEN 2
--         ELSE 1
--     END as F_score,

--     CASE 
--         WHEN monetary_value >= 2000 THEN 5
--         WHEN monetary_value >= 1500 THEN 4
--         WHEN monetary_value >= 1000 THEN 3
--         WHEN monetary_value >= 500 THEN 2
--         ELSE 1
--     END as M_score

-- FROM customer_rfm_metricsss;

-- SELECT 
--     customer_id,
--     recency_days,
--     frequency_count,
--     monetary_value,
--     R_score,
--     F_score,
--     M_score
-- FROM customer_rfm_scores
-- LIMIT 10;

-- CREATE TABLE customer_segments AS
-- SELECT *,
--     
--     CASE 
--         WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
--         
--         WHEN F_score >= 4 AND M_score >= 3 THEN 'Loyal Customers'
--         
--         WHEN R_score >= 3 AND F_score >= 3 THEN 'Potential Loyalists'
--         
--         WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
--         
--         WHEN R_score <= 2 AND F_score <= 2 THEN 'Hibernating'
--         
--         ELSE 'Others'
--     END as segment

-- FROM customer_rfm_scores;

-- SELECT segment, COUNT(*) 
-- FROM customer_segments
-- GROUP BY segment
-- ORDER BY COUNT(*) DESC;

-- Segment distribution 
-- SELECT 
--     segment,
--     COUNT(*) as customers,
--     ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) as percentage
-- FROM customer_segments
-- GROUP BY segment
-- ORDER BY customers DESC;

-- Most Revenue
-- SELECT 
--     segment,
--     SUM(monetary_value) as total_revenue,
--     AVG(monetary_value) as avg_revenue,
--     COUNT(*) as customers
-- FROM customer_segments
-- GROUP BY segment
-- ORDER BY total_revenue DESC;

