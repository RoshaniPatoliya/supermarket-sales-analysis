/*
=========================================================
              SUPERMARKET SALES ANALYSIS
=========================================================

Tool: PostgreSQL
Dataset: Supermarket Sales
Purpose:
- Analyze overall sales performance
- Identify top products, categories, and regions
- Track monthly revenue and month-over-month growth
- Analyze customer behavior and repeat customers
- Review payment methods and discount performance
=========================================================
*/

-- 1. DATA OVERVIEW
SELECT * FROM sales;

SELECT COUNT(*) AS total_rows
FROM sales;

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM sales;

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM sales;

-- 2. OVERALL SALES KPIs
SELECT
    ROUND(SUM(total_sales_sek), 2) AS total_revenue
FROM sales;

SELECT
    ROUND(AVG(total_sales_sek), 2) AS average_order_value
FROM sales;

-- 3. PRODUCT ANALYSIS
SELECT
    product,
    ROUND(SUM(total_sales_sek), 2) AS revenue
FROM sales
GROUP BY product
ORDER BY revenue DESC
LIMIT 5;

WITH product_sales AS (
    SELECT
        product,
        SUM(total_sales_sek) AS revenue
    FROM sales
    GROUP BY product
)
SELECT
    product,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM product_sales
ORDER BY revenue_rank;

WITH product_sales AS (
    SELECT
        category,
        product,
        SUM(total_sales_sek) AS revenue
    FROM sales
    GROUP BY category, product
)
SELECT
    category,
    product,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS product_rank
FROM product_sales
ORDER BY category, product_rank;

WITH product_sales AS (
    SELECT
        category,
        product,
        SUM(total_sales_sek) AS revenue
    FROM sales
    GROUP BY category, product
),
ranked_products AS (
    SELECT
        category,
        product,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS product_rank
    FROM product_sales
)
SELECT
    category,
    product,
    ROUND(revenue, 2) AS revenue
FROM ranked_products
WHERE product_rank = 1
ORDER BY revenue DESC;

-- 4. CATEGORY ANALYSIS
SELECT
    category,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_sales_sek), 2) AS revenue,
    ROUND(AVG(total_sales_sek), 2) AS avg_order_value
FROM sales
GROUP BY category
ORDER BY revenue DESC;

SELECT
    category,
    ROUND(SUM(total_sales_sek), 2) AS revenue,
    ROUND(
        SUM(total_sales_sek) * 100.0
        / SUM(SUM(total_sales_sek)) OVER (),
        2
    ) AS revenue_percentage
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- 5. REGIONAL ANALYSIS
SELECT
    region,
    ROUND(SUM(total_sales_sek), 2) AS revenue
FROM sales
GROUP BY region
ORDER BY revenue DESC;

SELECT
    region,
    ROUND(SUM(total_sales_sek), 2) AS revenue,
    ROUND(
        SUM(total_sales_sek) * 100.0
        / SUM(SUM(total_sales_sek)) OVER (),
        2
    ) AS revenue_percentage
FROM sales
GROUP BY region
ORDER BY revenue DESC;

-- 6. MONTHLY SALES TRENDS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    ROUND(SUM(total_sales_sek), 2) AS revenue
FROM sales
GROUP BY month
ORDER BY month;

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_sales_sek) AS revenue
    FROM sales
    GROUP BY month
),
sales_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_sales
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue - previous_revenue, 2) AS revenue_increase_sek,
    ROUND(
        (revenue - previous_revenue)
        / previous_revenue * 100,
        2
    ) AS growth_percentage
FROM sales_growth
ORDER BY month;

SELECT
    ROUND(SUM(total_sales_sek), 2) AS february_revenue
FROM sales
WHERE order_date >= '2026-02-01'
  AND order_date < '2026-03-01';

SELECT
    category,
    ROUND(SUM(total_sales_sek), 2) AS revenue
FROM sales
WHERE order_date >= '2026-02-01'
  AND order_date < '2026-03-01'
GROUP BY category
ORDER BY revenue DESC;

-- 7. CUSTOMER ANALYSIS
SELECT
    customer_id,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_sales_sek), 2) AS total_spent,
    ROUND(AVG(total_sales_sek), 2) AS avg_order_value
FROM sales
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 5;

SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM sales
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;

WITH repeat_customers AS (
    SELECT
        customer_id
    FROM sales
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
)
SELECT
    COUNT(*) AS repeat_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM sales) AS total_customers,
    ROUND(
        COUNT(*) * 100.0
        / (SELECT COUNT(DISTINCT customer_id) FROM sales),
        2
    ) AS repeat_customer_percentage
FROM repeat_customers;

-- 8. PAYMENT METHOD ANALYSIS
SELECT
    payment_method,
    COUNT(order_id) AS total_orders
FROM sales
GROUP BY payment_method
ORDER BY total_orders DESC;

SELECT
    payment_method,
    COUNT(order_id) AS total_orders,
    ROUND(
        COUNT(order_id) * 100.0
        / SUM(COUNT(order_id)) OVER (),
        2
    ) AS order_percentage
FROM sales
GROUP BY payment_method
ORDER BY total_orders DESC;

-- 9. DISCOUNT ANALYSIS
SELECT
    CASE
        WHEN discount > 0 THEN 'Discounted'
        ELSE 'No Discount'
    END AS discount_status,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(total_sales_sek), 2) AS avg_order_value
FROM sales
GROUP BY discount_status;

-- 10. FILTERING / DATA QUALITY
SELECT *
FROM sales
WHERE region = 'Unknown'
   OR payment_method = 'Unknown';

SELECT *
FROM sales
WHERE region = 'Stockholm'
  AND discount > 0;

SELECT *
FROM sales
WHERE region IN ('Stockholm', 'Uppsala')
  AND discount > 0;

SELECT *
FROM sales
WHERE total_sales_sek BETWEEN 50 AND 100;

SELECT
    product,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_sales_sek), 2) AS revenue
FROM sales
WHERE category = 'Beverages'
GROUP BY product
HAVING COUNT(order_id) > 5
ORDER BY revenue DESC;
