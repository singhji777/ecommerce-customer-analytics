-- 10 | Which products are returned/cancelled most (relative to what is sold)?
-- Concepts: conditional aggregation, HAVING to avoid tiny-sample noise, ratio ranking
SELECT stock_code, MAX(description) AS description,
       ROUND(SUM(CASE WHEN is_cancel = 0 THEN revenue END), 0)   AS gross_sales,
       ROUND(-SUM(CASE WHEN is_cancel = 1 THEN revenue END), 0)  AS returns_value,
       ROUND(-100.0 * SUM(CASE WHEN is_cancel = 1 THEN revenue END) / SUM(CASE WHEN is_cancel = 0 THEN revenue END), 1) AS return_rate_pct
FROM transactions
GROUP BY stock_code
HAVING gross_sales >= 5000
ORDER BY return_rate_pct DESC
LIMIT 10;
