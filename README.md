# E-commerce Customer Analytics (SQL + Python + Power BI export)

**Question:** who are the customers of a UK online wholesaler, what drives its revenue, and who is worth keeping?

**Data:** the public UCI *Online Retail* dataset: 541,909 invoice lines from Dec 2010 to 9 Dec 2011, about 4,300 identified customers. Real transactions, not simulated.
After cleaning, ~531k lines and ~GBP 9.8 M net revenue remain.

## Headline findings (all computed in the notebook)
| | |
|---|---|
| Strongly seasonal | Sep-Nov 2011 = 38% of the 12 full months' net revenue |
| Tiny core | Top 10% of customers = 60% of revenue; "Champions" are 19% of customers but 61% of revenue |
| Weak retention of new accounts | About 20-25% of a new cohort buys in any later month; 35% of customers buy only once (6.5% of revenue) |
| Honest modelling result | An out-of-time customer-value model (train on earlier windows, test on later ones) captured 66% of next-quarter revenue in its top 20%, **the same as just ranking by past spend (66%)**. Simple RFM is enough |
| Basket analysis | Co-purchases are sibling products (colour/design variants, matching pieces), stable on later baskets (median lift 20 early, 26 later) |
| Data quality | Two mistaken wholesale orders (GBP 77k, 168k) were reversed within minutes; ignoring cancellations overstates revenue by GBP 246k (2.5%) |

## What is in here
```
data/online_retail_raw.csv.gz   raw data (compressed)
src/build_db.py                 cleaning pipeline -> SQLite, with a logged reason for every removed row
sql/01..12_*.sql                12 standalone queries: cohorts, RFM, gaps-and-islands streaks, window functions, Pareto...
notebooks/05_ecommerce_customer_analytics.ipynb   full analysis, runs top to bottom
powerbi/                        star-schema CSVs + DASHBOARD_SPEC.md (pages, relationships, DAX)
images/                         charts used in the notebook
```

## Run it
```bash
pip install -r requirements.txt
python src/build_db.py          # builds data/ecommerce.db (~95 MB, git-ignored)
jupyter notebook notebooks/05_ecommerce_customer_analytics.ipynb
```

## Decisions worth discussing
- **Cancellations are kept as negative revenue**, and sales reversed by an identical cancellation are flagged, not deleted.
- **Guest checkouts** (no CustomerID, ~25% of lines) are excluded from customer analyses only.
- **Partial Dec-2011** and the **left-censored Dec-2010 cohort** are masked rather than interpreted.
- The value model is validated **out of time**, and compared against simple baselines and a perfect oracle.

## Limitations
One year of data (no year-over-year comparison); wholesale buyers, so conclusions may not transfer to consumer shops; basket rules are associations, not causes.
The Power BI dashboard is specified but you need to build it in Power BI Desktop (DAX in the spec is untested).

*Data: UCI Machine Learning Repository, "Online Retail" (Chen, 2015, CC BY 4.0). Check the licence terms there before redistributing.*
