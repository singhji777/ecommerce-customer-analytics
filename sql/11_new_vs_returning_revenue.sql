-- 11 | Each month's revenue split into customers buying for the first time (in the data) vs returning customers
-- Concepts: window MIN() OVER (PARTITION BY ...) to find first purchase month, conditional aggregation
-- CAVEAT: in 2010-12 every customer looks "new" because the data starts there.
WITH s AS (
    SELECT customer_id, strftime('%Y-%m', invoice_ts) AS month, revenue,
           MIN(strftime('%Y-%m', invoice_ts)) OVER (PARTITION BY customer_id) AS first_month
    FROM transactions WHERE is_cancel = 0 AND customer_id IS NOT NULL
)
SELECT month,
       ROUND(SUM(CASE WHEN month = first_month THEN revenue END), 0) AS new_customer_revenue,
       ROUND(SUM(CASE WHEN month > first_month THEN revenue END), 0) AS returning_customer_revenue,
       ROUND(100.0 * SUM(CASE WHEN month > first_month THEN revenue END) / SUM(revenue), 1) AS pct_from_returning
FROM s
GROUP BY month
ORDER BY month;
