-- 03 | Revenue by country: customers, orders, average order value and share of net revenue
-- Concepts: GROUP BY, COUNT(DISTINCT), window share-of-total
SELECT country,
       COUNT(DISTINCT customer_id)                                              AS customers,
       COUNT(DISTINCT CASE WHEN is_cancel = 0 THEN invoice_no END)              AS orders,
       ROUND(SUM(revenue), 0)                                                   AS net_revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)               AS share_pct,
       ROUND(1.0 * SUM(CASE WHEN is_cancel = 0 THEN revenue END)
             / COUNT(DISTINCT CASE WHEN is_cancel = 0 THEN invoice_no END), 0)  AS avg_order_value
FROM transactions
GROUP BY country
ORDER BY net_revenue DESC
LIMIT 10;
