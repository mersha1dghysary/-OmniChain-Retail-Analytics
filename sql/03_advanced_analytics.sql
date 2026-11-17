-- ==============================================================================
-- Project: OmniChain - Retail Store Performance & Customer Intelligence Pipeline
-- Script: 03_advanced_analytics.sql
-- Description: Advanced analytical queries covering Pareto (80/20), Cross-Store
--              Leakage, Store Productivity, Basket Affinity, and RFM Segmentation.
-- ==============================================================================

USE OmniChainDB;
GO

-- ==============================================================================
-- 1. Pareto 80/20 & Cumulative Revenue Analysis (Window Functions)
-- Objective: Identify core high-yield products generating the top 80% revenue.
-- ==============================================================================
WITH ProductSales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        SUM(o.total_price) AS product_revenue
    FROM Orders o
    JOIN Products p ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category
),
CumulativeAnalysis AS (
    SELECT 
        product_id,
        product_name,
        category,
        product_revenue,
        SUM(product_revenue) OVER () AS grand_total_revenue,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC) AS running_total_revenue
    FROM ProductSales
)
SELECT 
    product_name,
    category,
    product_revenue,
    ROUND((product_revenue / grand_total_revenue) * 100.0, 2) AS revenue_share_pct,
    ROUND((running_total_revenue / grand_total_revenue) * 100.0, 2) AS cumulative_share_pct,
    CASE 
        WHEN (running_total_revenue / grand_total_revenue) * 100.0 <= 80.0 THEN 'Strategic Core (Top 80%)'
        ELSE 'Long Tail / Complementary (Tail 20%)'
    END AS pareto_class
FROM CumulativeAnalysis
ORDER BY product_revenue DESC;
GO

-- ==============================================================================
-- 2. Cross-Store Customer Leakage & Store Loyalty
-- Objective: Determine spending share at registered home store vs. outside stores.
-- ==============================================================================
SELECT 
    c.tier,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_price) AS total_spent,
    SUM(CASE WHEN o.store_id = c.home_store_id THEN o.total_price ELSE 0 END) AS home_store_spent,
    SUM(CASE WHEN o.store_id <> c.home_store_id THEN o.total_price ELSE 0 END) AS outside_store_spent,
    ROUND(
        (SUM(CASE WHEN o.store_id <> c.home_store_id THEN o.total_price ELSE 0 END) * 100.0) / 
        NULLIF(SUM(o.total_price), 0), 2
    ) AS cross_shopping_leakage_pct
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
WHERE o.customer_id <> 0 -- Exclude guest transactions for registered loyalty audit
GROUP BY c.tier
ORDER BY total_spent DESC;
GO

-- ==============================================================================
-- 3. Executive Store Productivity Scorecard
-- Objective: Extract composite sales, AOV, and sales-per-sqm metrics for retail strategy.
-- ==============================================================================
SELECT 
    s.store_id,
    s.store_name,
    s.store_type,
    s.area_sqm,
    COUNT(DISTINCT o.order_id) AS total_transactions,
    SUM(o.quantity) AS total_units_sold,
    SUM(o.total_price) AS gross_revenue,
    ROUND(AVG(o.total_price * 1.0), 0) AS average_order_value,
    ROUND(SUM(o.total_price) * 1.0 / NULLIF(s.area_sqm, 0), 2) AS sales_per_sqm,
    DENSE_RANK() OVER (ORDER BY (SUM(o.total_price) * 1.0 / NULLIF(s.area_sqm, 0)) DESC) AS efficiency_rank
FROM Stores s
LEFT JOIN Orders o ON s.store_id = o.store_id
GROUP BY s.store_id, s.store_name, s.store_type, s.area_sqm
ORDER BY sales_per_sqm DESC;
GO

-- ==============================================================================
-- 4. Market Basket Analysis (Item Affinity & Co-occurrence)
-- Objective: Discover item pairs co-purchased in the same order.
-- Note: Evaluates transactions containing multi-item baskets.
-- ==============================================================================
WITH OrderBaskets AS (
    SELECT 
        o1.order_id,
        p1.product_name AS item_a,
        p2.product_name AS item_b
    FROM Orders o1
    JOIN Orders o2 ON o1.order_id = o2.order_id AND o1.product_id < o2.product_id
    JOIN Products p1 ON o1.product_id = p1.product_id
    JOIN Products p2 ON o2.product_id = p2.product_id
)
SELECT 
    item_a,
    item_b,
    COUNT(order_id) AS co_occurrence_count,
    DENSE_RANK() OVER (ORDER BY COUNT(order_id) DESC) AS affinity_rank
FROM OrderBaskets
GROUP BY item_a, item_b
ORDER BY co_occurrence_count DESC;
GO

-- ==============================================================================
-- 5. RFM Customer Segmentation (Recency, Frequency, Monetary)
-- Objective: Segment registered customers into actionable clusters using NTILE percentiles.
-- ==============================================================================
WITH CustomerRFM_Raw AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.tier,
        DATEDIFF(day, MAX(o.order_date), '2024-12-31') AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        SUM(o.total_price) AS monetary_value
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    WHERE c.customer_id <> 0 -- Exclude guest transactions
    GROUP BY c.customer_id, c.full_name, c.tier
),
RFM_Scores AS (
    SELECT 
        customer_id,
        full_name,
        tier,
        recency_days,
        frequency_orders,
        monetary_value,
        NTILE(3) OVER (ORDER BY recency_days DESC) AS r_score,     -- Higher score = more recent
        NTILE(3) OVER (ORDER BY frequency_orders ASC) AS f_score,  -- Higher score = more frequent
        NTILE(3) OVER (ORDER BY monetary_value ASC) AS m_score     -- Higher score = higher spend
    FROM CustomerRFM_Raw
)
SELECT 
    customer_id,
    full_name,
    tier,
    recency_days,
    frequency_orders,
    monetary_value,
    (r_score + f_score + m_score) AS rfm_total_score,
    CASE 
        WHEN (r_score + f_score + m_score) >= 7 THEN 'Champions'
        WHEN (r_score + f_score + m_score) BETWEEN 4 AND 6 THEN 'Potential Growth'
        ELSE 'At Risk'
    END AS customer_segment
FROM RFM_Scores
ORDER BY rfm_total_score DESC, monetary_value DESC;
GO

-- ==============================================================================
-- 6. Category Performance vs. Network Benchmark
-- Objective: Quantify category revenue variance relative to average departmental sales.
-- ==============================================================================
WITH CategoryRevenue AS (
    SELECT 
        p.category,
        SUM(o.total_price) AS cat_revenue,
        COUNT(DISTINCT o.order_id) AS cat_orders,
        SUM(o.quantity) AS cat_units
    FROM Products p
    JOIN Orders o ON p.product_id = o.product_id
    GROUP BY p.category
),
NetworkAverage AS (
    SELECT 
        AVG(cat_revenue * 1.0) AS avg_cat_revenue
    FROM CategoryRevenue
)
SELECT 
    c.category,
    c.cat_revenue,
    c.cat_orders,
    c.cat_units,
    ROUND(n.avg_cat_revenue, 0) AS network_category_average,
    ROUND(c.cat_revenue - n.avg_cat_revenue, 0) AS variance_from_average,
    CASE 
        WHEN c.cat_revenue >= n.avg_cat_revenue THEN 'Outperformer'
        ELSE 'Underperformer'
    END AS performance_status
FROM CategoryRevenue c
CROSS JOIN NetworkAverage n
ORDER BY c.cat_revenue DESC;
GO
