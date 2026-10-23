-- 09 | "Gaps and islands": the longest run of consecutive active months per customer
-- Classic interview pattern: month_index - ROW_NUMBER() is constant inside a run of consecutive months.
-- Concepts: DISTINCT months, ROW_NUMBER() OVER (PARTITION BY ...), grouping by the derived island id
WITH months AS (
    SELECT DISTINCT customer_id,
           CAST(strftime('%Y', invoice_ts) AS INT) * 12 + CAST(strftime('%m', invoice_ts) AS INT) AS mi
    FROM transactions WHERE is_cancel = 0 AND customer_id IS NOT NULL
),
islands AS (
    SELECT customer_id, mi, mi - ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY mi) AS island FROM months
),
streaks AS (SELECT customer_id, island, COUNT(*) AS streak_len FROM islands GROUP BY customer_id, island),
best AS (SELECT customer_id, MAX(streak_len) AS longest_streak FROM streaks GROUP BY customer_id)
SELECT longest_streak AS longest_consecutive_months, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers
FROM best
GROUP BY longest_streak
ORDER BY longest_streak;
