-- 08 | Customer value concentration: revenue share by spend decile (decile 1 = best customers)
-- Concepts: NTILE(10), nested window aggregates, cumulative share
WITH spend AS (
    SELECT customer_id, SUM(revenue) AS net_revenue
    FROM transactions WHERE customer_id IS NOT NULL GROUP BY customer_id HAVING net_revenue > 0
),
tiered AS (SELECT *, NTILE(10) OVER (ORDER BY net_revenue DESC) AS decile FROM spend)
SELECT decile, COUNT(*) AS customers, ROUND(AVG(net_revenue), 0) AS avg_revenue,
       ROUND(100.0 * SUM(net_revenue) / SUM(SUM(net_revenue)) OVER (), 1)                              AS pct_of_revenue,
       ROUND(100.0 * SUM(SUM(net_revenue)) OVER (ORDER BY decile) / SUM(SUM(net_revenue)) OVER (), 1)  AS cumulative_pct
FROM tiered
GROUP BY decile
ORDER BY decile;
