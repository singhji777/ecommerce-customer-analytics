-- 07 | RFM customer segmentation done entirely in SQL
-- R = days since last order (NTILE, lower is better), F = order-count bands, M = gross spend (NTILE)
-- Concepts: CTEs, NTILE, CASE scoring, segment roll-up with revenue share
-- Frequency uses fixed bands instead of NTILE: many customers share the same order count, and NTILE would split those ties arbitrarily.
WITH cust AS (
    SELECT customer_id,
           CAST(julianday('2011-12-10') - julianday(MAX(invoice_ts)) AS INT)  AS recency_days,
           COUNT(DISTINCT invoice_no)                                         AS frequency,
           SUM(revenue)                                                       AS monetary
    FROM transactions WHERE is_cancel = 0 AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored AS (
    SELECT *,
           6 - NTILE(5) OVER (ORDER BY recency_days)                                         AS r_score,   -- most recent = 5
           CASE WHEN frequency >= 9 THEN 5 WHEN frequency >= 5 THEN 4 WHEN frequency >= 3 THEN 3
                WHEN frequency = 2 THEN 2 ELSE 1 END                                         AS f_score,
           NTILE(5) OVER (ORDER BY monetary)                                                 AS m_score
    FROM cust
),
labelled AS (
    SELECT *, CASE WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
                   WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
                   WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
                   WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
                   WHEN r_score <= 2                  THEN 'Hibernating'
                   ELSE 'Need Attention' END AS segment
    FROM scored
)
SELECT segment, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                          AS pct_customers,
       ROUND(AVG(recency_days), 0)                                                 AS avg_recency_days,
       ROUND(AVG(frequency), 1)                                                    AS avg_orders,
       ROUND(SUM(monetary), 0)                                                     AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1)                AS pct_revenue
FROM labelled
GROUP BY segment
ORDER BY revenue DESC;
