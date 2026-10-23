-- 05 | How many orders does a customer place, and how much revenue does each group bring?
-- Concepts: aggregate of an aggregate, CASE bucketing, share of total with a window
WITH cust AS (
    SELECT customer_id,
           COUNT(DISTINCT CASE WHEN is_cancel = 0 THEN invoice_no END) AS orders,
           SUM(revenue)                                                AS net_revenue
    FROM transactions WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING orders > 0
)
SELECT CASE WHEN orders = 1 THEN '1 order'  WHEN orders = 2 THEN '2 orders' WHEN orders <= 4 THEN '3-4 orders'
            WHEN orders <= 8 THEN '5-8 orders' ELSE '9+ orders' END                    AS order_band,
       COUNT(*)                                                                         AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                               AS pct_customers,
       ROUND(SUM(net_revenue), 0)                                                       AS net_revenue,
       ROUND(100.0 * SUM(net_revenue) / SUM(SUM(net_revenue)) OVER (), 1)               AS pct_revenue
FROM cust
GROUP BY order_band
ORDER BY MIN(orders);
