-- =====================================================
-- SQL Script 3: RFM Analysis
-- Project: E-Commerce Customer Segmentation Analysis
-- Purpose: Calculate RFM scores and segment customers
-- =====================================================

USE ecommerce_analysis;

-- =====================================================
-- PART 1: CALCULATE RFM METRICS
-- =====================================================

-- Set analysis date (use current date or a specific date)
SET @analysis_date = CURRENT_DATE;
-- OR use a specific date for consistency: SET @analysis_date = '2026-04-13';

-- Create RFM metrics table
DROP TABLE IF EXISTS customer_rfm_metrics;

CREATE TABLE customer_rfm_metrics AS
SELECT 
    c.customer_id,
    c.first_name,
    c.email,
    c.country,
    c.age_group,
    
    -- RECENCY: Days since last purchase (lower is better)
    DATEDIFF(@analysis_date, MAX(o.order_date)) as recency_days,
    
    -- FREQUENCY: Number of purchases (higher is better)
    COUNT(DISTINCT o.order_id) as frequency_count,
    
    -- MONETARY: Total spending (higher is better)
    SUM(o.order_total) as monetary_value,
    
    -- Additional useful metrics
    AVG(o.order_total) as avg_order_value,
    MIN(o.order_date) as first_purchase_date,
    MAX(o.order_date) as last_purchase_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_lifespan_days

FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.email, 
    c.country, 
    c.age_group
HAVING COUNT(DISTINCT o.order_id) > 0;  -- Only customers with at least one completed order

-- View the results
SELECT * FROM customer_rfm_metrics
ORDER BY monetary_value DESC
LIMIT 20;

-- =====================================================
-- PART 2: CALCULATE RFM SCORES (1-5 scale)
-- =====================================================

-- Score customers using NTILE function
-- For Recency: Lower days = Higher score (5 is best)
-- For Frequency: Higher count = Higher score (5 is best)
-- For Monetary: Higher value = Higher score (5 is best)

DROP TABLE IF EXISTS customer_rfm_scores;

CREATE TABLE customer_rfm_scores AS
SELECT 
    customer_id,
    first_name,
    email,
    country,
    age_group,
    recency_days,
    frequency_count,
    monetary_value,
    avg_order_value,
    
    -- Calculate RFM scores (1-5 scale)
    -- RECENCY: Reverse the NTILE because lower days = better
    (6 - NTILE(5) OVER (ORDER BY recency_days)) as R_score,
    
    -- FREQUENCY: Higher is better
    NTILE(5) OVER (ORDER BY frequency_count) as F_score,
    
    -- MONETARY: Higher is better
    NTILE(5) OVER (ORDER BY monetary_value) as M_score

FROM customer_rfm_metrics;

-- Add combined RFM score
ALTER TABLE customer_rfm_scores
ADD COLUMN rfm_score VARCHAR(3);

UPDATE customer_rfm_scores
SET rfm_score = CONCAT(R_score, F_score, M_score);

-- Add total score for easier sorting
ALTER TABLE customer_rfm_scores
ADD COLUMN rfm_total INT;

UPDATE customer_rfm_scores
SET rfm_total = R_score + F_score + M_score;

-- View results
SELECT 
    customer_id,
    first_name,
    recency_days,
    frequency_count,
    monetary_value,
    R_score,
    F_score,
    M_score,
    rfm_score,
    rfm_total
FROM customer_rfm_scores
ORDER BY rfm_total DESC, monetary_value DESC
LIMIT 20;

-- =====================================================
-- PART 3: SEGMENT CUSTOMERS BASED ON RFM
-- =====================================================

-- Create customer segments table
DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments AS
SELECT 
    *,
    CASE
        -- Champions: Best customers - bought recently, buy often and spend the most
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        
        -- Loyal Customers: Buy regularly, spend good money
        WHEN R_score >= 3 AND F_score >= 4 AND M_score >= 3 THEN 'Loyal Customers'
        
        -- Potential Loyalists: Recent customers with average frequency
        WHEN R_score >= 4 AND F_score >= 2 AND F_score <= 3 THEN 'Potential Loyalists'
        
        -- Recent Customers: Bought recently but not often
        WHEN R_score >= 4 AND F_score <= 2 THEN 'Recent Customers'
        
        -- Promising: Recent shoppers with potential
        WHEN R_score >= 3 AND R_score <= 4 AND F_score <= 2 THEN 'Promising'
        
        -- Need Attention: Above average recency, frequency and monetary values
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Need Attention'
        
        -- About to Sleep: Below average recency, frequency and monetary values
        WHEN R_score <= 3 AND F_score <= 3 THEN 'About To Sleep'
        
        -- At Risk: Spent big money, purchased often but long time ago
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'At Risk'
        
        -- Cannot Lose Them: Made big purchases and often, but long time ago
        WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 4 THEN 'Cannot Lose Them'
        
        -- Hibernating: Last purchase long ago, low spenders
        WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Hibernating'
        
        -- Lost: Lowest recency, frequency and monetary scores
        WHEN R_score = 1 THEN 'Lost'
        
        ELSE 'Others'
    END as segment,
    
    -- Add segment priority for action planning
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 1  -- Champions
        WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 4 THEN 2  -- Cannot Lose Them
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 3  -- At Risk
        WHEN R_score >= 3 AND F_score >= 4 AND M_score >= 3 THEN 4  -- Loyal Customers
        WHEN R_score >= 4 AND F_score >= 2 AND F_score <= 3 THEN 5  -- Potential Loyalists
        ELSE 6
    END as segment_priority

FROM customer_rfm_scores;

-- =====================================================
-- PART 4: SEGMENT ANALYSIS
-- =====================================================

-- Segment distribution and metrics
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) as percentage,
    ROUND(AVG(recency_days), 0) as avg_recency,
    ROUND(AVG(frequency_count), 1) as avg_frequency,
    ROUND(AVG(monetary_value), 2) as avg_monetary,
    ROUND(SUM(monetary_value), 2) as total_revenue,
    ROUND(SUM(monetary_value) * 100.0 / (SELECT SUM(monetary_value) FROM customer_segments), 2) as revenue_percentage,
    MIN(segment_priority) as priority
FROM customer_segments
GROUP BY segment
ORDER BY priority, total_revenue DESC;

-- Top customers by segment
SELECT 
    segment,
    customer_id,
    first_name,
    email,
    recency_days,
    frequency_count,
    monetary_value,
    rfm_score
FROM customer_segments
WHERE segment IN ('Champions', 'Loyal Customers', 'Cannot Lose Them', 'At Risk')
ORDER BY segment, monetary_value DESC;

-- Segment trends over time (cohort-style analysis)
SELECT 
    segment,
    CASE 
        WHEN recency_days <= 30 THEN 'Last 30 days'
        WHEN recency_days <= 60 THEN '31-60 days'
        WHEN recency_days <= 90 THEN '61-90 days'
        WHEN recency_days <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END as recency_group,
    COUNT(*) as customer_count,
    ROUND(AVG(monetary_value), 2) as avg_value
FROM customer_segments
GROUP BY segment, recency_group
ORDER BY segment, 
    FIELD(recency_group, 'Last 30 days', '31-60 days', '61-90 days', '91-180 days', '180+ days');

-- Geographic distribution by segment
SELECT 
    segment,
    country,
    COUNT(*) as customer_count,
    ROUND(SUM(monetary_value), 2) as total_revenue
FROM customer_segments
GROUP BY segment, country
ORDER BY segment, total_revenue DESC;

-- Age group distribution by segment
SELECT 
    segment,
    age_group,
    COUNT(*) as customer_count,
    ROUND(AVG(monetary_value), 2) as avg_value
FROM customer_segments
GROUP BY segment, age_group
ORDER BY segment, age_group;

-- =====================================================
-- PART 5: ACTIONABLE INSIGHTS
-- =====================================================

-- High-value at-risk customers (immediate action needed)
SELECT 
    customer_id,
    first_name,
    email,
    segment,
    recency_days,
    frequency_count,
    monetary_value,
    rfm_score,
    'Send personalized win-back offer' as recommended_action
FROM customer_segments
WHERE segment IN ('Cannot Lose Them', 'At Risk')
ORDER BY monetary_value DESC
LIMIT 50;

-- Potential loyalists to nurture
SELECT 
    customer_id,
    first_name,
    email,
    segment,
    recency_days,
    frequency_count,
    monetary_value,
    'Send loyalty program invitation' as recommended_action
FROM customer_segments
WHERE segment = 'Potential Loyalists'
ORDER BY monetary_value DESC
LIMIT 50;

-- Champions for VIP treatment and referrals
SELECT 
    customer_id,
    first_name,
    email,
    segment,
    frequency_count,
    monetary_value,
    'Request review/referral, offer exclusive perks' as recommended_action
FROM customer_segments
WHERE segment = 'Champions'
ORDER BY monetary_value DESC
LIMIT 50;

-- Hibernating customers to re-engage
SELECT 
    customer_id,
    first_name,
    email,
    segment,
    recency_days,
    monetary_value,
    'Send re-engagement campaign with discount' as recommended_action
FROM customer_segments
WHERE segment IN ('Hibernating', 'About To Sleep')
    AND monetary_value > (SELECT AVG(monetary_value) FROM customer_segments)
ORDER BY monetary_value DESC
LIMIT 50;

-- =====================================================
-- PART 6: CUSTOMER LIFETIME VALUE (CLV) ESTIMATION
-- =====================================================

DROP TABLE IF EXISTS customer_clv;

CREATE TABLE customer_clv AS
SELECT 
    cs.*,
    
    -- Average purchase frequency (purchases per year)
    CASE 
        WHEN cm.customer_lifespan_days > 0 
        THEN (frequency_count * 365.0) / cm.customer_lifespan_days
        ELSE frequency_count
    END as purchase_frequency_yearly,
    
    -- Estimated Customer Lifetime Value (simplified)
    -- CLV = Avg Order Value × Purchase Frequency × Customer Lifespan (assumed 3 years)
    ROUND(
        avg_order_value * 
        CASE 
            WHEN cm.customer_lifespan_days > 0 
            THEN (frequency_count * 365.0 * 3) / cm.customer_lifespan_days
            ELSE frequency_count * 3
        END,
        2
    ) as estimated_clv

FROM customer_segments cs
JOIN customer_rfm_metrics cm ON cs.customer_id = cm.customer_id;

-- CLV by segment
SELECT 
    segment,
    COUNT(*) as customers,
    ROUND(AVG(estimated_clv), 2) as avg_clv,
    ROUND(SUM(estimated_clv), 2) as total_potential_clv,
    ROUND(MIN(estimated_clv), 2) as min_clv,
    ROUND(MAX(estimated_clv), 2) as max_clv
FROM customer_clv
GROUP BY segment
ORDER BY avg_clv DESC;

-- =====================================================
-- PART 7: EXPORT FINAL DATASET FOR POWER BI
-- =====================================================

-- Create final comprehensive view for Power BI import
CREATE OR REPLACE VIEW vw_customer_segmentation_final AS
SELECT 
    clv.customer_id,
    clv.first_name,
    clv.email,
    clv.country,
    clv.age_group,
    clv.segment,
    clv.segment_priority,
    clv.recency_days,
    clv.frequency_count,
    clv.monetary_value,
    clv.avg_order_value,
    clv.R_score,
    clv.F_score,
    clv.M_score,
    clv.rfm_score,
    clv.rfm_total,
    clv.estimated_clv,
    clv.purchase_frequency_yearly,
    cm.first_purchase_date,
    cm.last_purchase_date,
    cm.customer_lifespan_days,
    
    -- Additional derived fields
    DATEDIFF(@analysis_date, cm.first_purchase_date) as days_as_customer,
    CASE 
        WHEN clv.segment IN ('Champions', 'Loyal Customers') THEN 'Retain & Grow'
        WHEN clv.segment IN ('Cannot Lose Them', 'At Risk') THEN 'Win Back'
        WHEN clv.segment IN ('Potential Loyalists', 'Promising') THEN 'Nurture'
        WHEN clv.segment IN ('Recent Customers') THEN 'Onboard'
        ELSE 'Re-engage'
    END as marketing_strategy
    
FROM customer_clv clv
JOIN customer_rfm_metrics cm ON clv.customer_id = cm.customer_id;

-- Sample the final dataset
SELECT * FROM vw_customer_segmentation_final LIMIT 100;

-- Export summary statistics
SELECT 
    'Total Customers Analyzed' as metric,
    COUNT(*) as value
FROM vw_customer_segmentation_final
UNION ALL
SELECT 
    'Total Revenue',
    ROUND(SUM(monetary_value), 2)
FROM vw_customer_segmentation_final
UNION ALL
SELECT 
    'Total Estimated CLV',
    ROUND(SUM(estimated_clv), 2)
FROM vw_customer_segmentation_final
UNION ALL
SELECT 
    'Average CLV per Customer',
    ROUND(AVG(estimated_clv), 2)
FROM vw_customer_segmentation_final;

-- =====================================================
-- Script complete!
-- Next steps:
-- 1. Export vw_customer_segmentation_final to CSV
-- 2. Import into Power BI
-- 3. Create visualizations and dashboards
-- =====================================================
