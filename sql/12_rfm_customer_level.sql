-- 12 | Customer-level RFM table (same scoring logic as 07, but one row per customer). Used to feed the Power BI customer dimension.
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
           6 - NTILE(5) OVER (ORDER BY recency_days)                                         AS r_score,
           CASE WHEN frequency >= 9 THEN 5 WHEN frequency >= 5 THEN 4 WHEN frequency >= 3 THEN 3
                WHEN frequency = 2 THEN 2 ELSE 1 END                                         AS f_score,
           NTILE(5) OVER (ORDER BY monetary)                                                 AS m_score
    FROM cust
)
SELECT customer_id, recency_days, frequency, ROUND(monetary, 2) AS monetary, r_score, f_score, m_score,
       CASE WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2                  THEN 'Hibernating'
            ELSE 'Need Attention' END AS segment
FROM scored;
