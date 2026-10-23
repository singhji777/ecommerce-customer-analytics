-- 01 | Monthly KPIs: gross sales, returns, net revenue, orders, active customers, AOV, return rate, MoM growth
-- Concepts: CTE, conditional aggregation, COUNT(DISTINCT CASE ...), LAG window function
-- NOTE: Dec-2011 contains data only up to 9 Dec, so its totals are partial.
WITH m AS (
    SELECT strftime('%Y-%m', invoice_ts)                                           AS month,
           ROUND(SUM(CASE WHEN is_cancel = 0 THEN revenue END), 0)                 AS gross_sales,
           ROUND(SUM(CASE WHEN is_cancel = 1 THEN revenue END), 0)                 AS returns_value,
           ROUND(SUM(revenue), 0)                                                  AS net_revenue,
           COUNT(DISTINCT CASE WHEN is_cancel = 0 THEN invoice_no END)             AS orders,
           COUNT(DISTINCT CASE WHEN is_cancel = 0 THEN customer_id END)            AS active_customers
    FROM transactions
    GROUP BY 1
)
SELECT month, gross_sales, returns_value, net_revenue, orders, active_customers,
       ROUND(1.0 * gross_sales / orders, 1)                                        AS avg_order_value,
       ROUND(-100.0 * returns_value / gross_sales, 1)                              AS return_rate_pct,
       ROUND(100.0 * (net_revenue - LAG(net_revenue) OVER (ORDER BY month))
             / LAG(net_revenue) OVER (ORDER BY month), 1)                          AS net_mom_pct
FROM m
ORDER BY month;
