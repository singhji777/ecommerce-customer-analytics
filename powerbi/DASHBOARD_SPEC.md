# Power BI dashboard spec

The notebook exports a ready-made **star schema** to `powerbi/data/`. This file tells you how to build the dashboard from it.
> **Note:** the DAX below was written but **not tested in Power BI Desktop** (it was prepared outside Windows). Build it yourself, fix any syntax issues, and
> then you genuinely own the dashboard. Take a screenshot into `images/dashboard.png` and link it in the README.

## 1. Load and relate
Get Data > Text/CSV for the five files. Relationships (all one-to-many, single direction):

| From (one) | To (many) |
|---|---|
| `dim_date[date]` | `fact_invoice[invoice_date]` |
| `dim_customer[customer_id]` | `fact_invoice[customer_id]` |
| `dim_product[stock_code]` | `fact_product_month[stock_code]` |
| `dim_date[date]` | `fact_product_month[month_start]` |

Mark `dim_date` as the date table. `fact_invoice` contains only identified customers; guest checkouts are excluded (see README).
Sort `dim_date[month_name]` by `month_num`.

## 2. Measures
```DAX
Net Revenue   = SUM ( fact_invoice[revenue] )
Orders        = CALCULATE ( DISTINCTCOUNT ( fact_invoice[invoice_no] ), fact_invoice[is_cancel] = FALSE() )
Customers     = DISTINCTCOUNT ( fact_invoice[customer_id] )
AOV           = DIVIDE ( CALCULATE ( SUM ( fact_invoice[revenue] ), fact_invoice[is_cancel] = FALSE() ), [Orders] )
Gross Sales   = SUMX ( FILTER ( fact_product_month, TRUE() ), fact_product_month[gross_sales] )
Return Rate   = DIVIDE ( SUM ( fact_product_month[returns_value] ), [Gross Sales] )
Revenue MoM % = VAR prev = CALCULATE ( [Net Revenue], DATEADD ( dim_date[date], -1, MONTH ) )
                RETURN DIVIDE ( [Net Revenue] - prev, prev )
Repeat Customers = CALCULATE ( COUNTROWS ( dim_customer ), dim_customer[orders] >= 2 )
Repeat Rate   = DIVIDE ( [Repeat Customers], COUNTROWS ( dim_customer ) )
```
(If `returns_value` is stored as a positive number the formula works as written; if negative, wrap it in `ABS`.)

## 3. Pages
1. **Overview** - KPI cards (Net Revenue, Orders, Customers, AOV), monthly revenue line with the partial Dec-2011 month greyed (use `dim_date[is_partial_month]`), country slicer.
2. **Customers** - segment bar (customers vs revenue share by `dim_customer[segment]`), recency vs spend scatter, table of "At Risk" customers sorted by `net_revenue` (this is the win-back list).
3. **Products** - Pareto of revenue by product, return-rate table with a minimum-volume filter, top-N slicer.
4. **Data notes** - text box repeating the cleaning decisions (dupes, non-product codes, mistaken orders, guest checkouts).

## 4. What to say about it in an interview
"I modelled it as a star schema so every measure is a simple aggregation. I decided up front that guest checkouts are excluded from customer pages
and that the incomplete Dec-2011 month is flagged rather than shown as a collapse."
