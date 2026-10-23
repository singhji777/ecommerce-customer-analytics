-- 02 | Top 20 products by net revenue with each product's share and the running (Pareto) share
-- Concepts: aggregate CTE, SUM() OVER () for share of total, running SUM() OVER (ORDER BY ...), RANK
WITH p AS (
    SELECT stock_code,
           MAX(description)                                         AS description,
           SUM(CASE WHEN is_cancel = 0 THEN quantity END)           AS units_sold,
           SUM(revenue)                                             AS net_revenue
    FROM transactions
    GROUP BY stock_code
)
SELECT RANK() OVER (ORDER BY net_revenue DESC)                      AS rnk,
       stock_code, description, units_sold, ROUND(net_revenue, 0)   AS net_revenue,
       ROUND(100.0 * net_revenue / SUM(net_revenue) OVER (), 2)     AS share_pct,
       ROUND(100.0 * SUM(net_revenue) OVER (ORDER BY net_revenue DESC) / SUM(net_revenue) OVER (), 1) AS cumulative_share_pct
FROM p
ORDER BY net_revenue DESC
LIMIT 20;
