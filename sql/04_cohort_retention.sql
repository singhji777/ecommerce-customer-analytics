-- 04 | Monthly acquisition-cohort retention (known customers only)
-- Cohort = month of a customer's first purchase in the data. Retention = % of the cohort that buys again N months later.
-- Concepts: multi-step CTEs, month arithmetic, COUNT(DISTINCT), USING joins
-- CAVEAT: the 2010-12 "cohort" is every customer already active when the data starts, not truly new customers.
WITH orders AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', invoice_ts) AS ym
    FROM transactions WHERE is_cancel = 0 AND customer_id IS NOT NULL
),
first_buy AS (SELECT customer_id, MIN(ym) AS cohort FROM orders GROUP BY customer_id),
activity AS (
    SELECT f.cohort,
           (CAST(substr(o.ym, 1, 4) AS INT) * 12 + CAST(substr(o.ym, 6, 2) AS INT))
         - (CAST(substr(f.cohort, 1, 4) AS INT) * 12 + CAST(substr(f.cohort, 6, 2) AS INT)) AS month_number,
           COUNT(DISTINCT o.customer_id) AS active_customers
    FROM orders o JOIN first_buy f USING (customer_id)
    GROUP BY 1, 2
),
cohort_size AS (SELECT cohort, COUNT(*) AS cohort_customers FROM first_buy GROUP BY cohort)
SELECT a.cohort, s.cohort_customers, a.month_number, a.active_customers,
       ROUND(100.0 * a.active_customers / s.cohort_customers, 1) AS retention_pct
FROM activity a JOIN cohort_size s USING (cohort)
ORDER BY a.cohort, a.month_number;
