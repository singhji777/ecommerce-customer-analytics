-- 06 | Time between consecutive orders of the same customer (repeat-purchase rhythm)
-- Concepts: LAG() OVER (PARTITION BY ... ORDER BY ...), julianday date arithmetic, bucketing
WITH inv AS (
    SELECT customer_id, invoice_no, date(MIN(invoice_ts)) AS order_date
    FROM transactions WHERE is_cancel = 0 AND customer_id IS NOT NULL
    GROUP BY customer_id, invoice_no
),
gaps AS (
    SELECT customer_id,
           julianday(order_date) - julianday(LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, invoice_no)) AS gap_days
    FROM inv
)
SELECT CASE WHEN gap_days = 0 THEN 'same day' WHEN gap_days <= 7 THEN '1-7 days' WHEN gap_days <= 14 THEN '8-14 days'
            WHEN gap_days <= 30 THEN '15-30 days' WHEN gap_days <= 60 THEN '31-60 days' WHEN gap_days <= 90 THEN '61-90 days'
            ELSE '90+ days' END                                              AS gap_band,
       COUNT(*)                                                              AS repeat_orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                    AS pct_of_repeat_orders,
       ROUND(AVG(gap_days), 1)                                               AS avg_gap_days
FROM gaps
WHERE gap_days IS NOT NULL
GROUP BY gap_band
ORDER BY MIN(gap_days);
