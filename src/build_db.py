"""Cleans the raw UCI 'Online Retail' transactions and loads them into SQLite (data/ecommerce.db).

Every cleaning step is logged to the `cleaning_log` table so the notebook can show exactly what was removed and why.
Usage:  python src/build_db.py            (reads data/online_retail_raw.csv.gz)
"""
import sqlite3, sys
import numpy as np, pandas as pd
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "data" / "online_retail_raw.csv.gz"
DB = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "data" / "ecommerce.db"

df = pd.read_csv(RAW, dtype={"InvoiceNo": str, "StockCode": str})
log = [("raw file", 0, len(df), "541,909 transaction lines, 8 columns")]
def step(name, mask_drop, note):
    global df
    n = int(mask_drop.sum()); df = df[~mask_drop].copy(); log.append((name, n, len(df), note))

step("exact duplicate rows", df.duplicated(), "identical lines (likely double-scanned); kept the first")
# product codes are 5 digits + optional letters (e.g. 85123A). POST, DOT, M, D, S, AMAZONFEE, CRUK, BANK CHARGES, gift vouchers... are not products
step("non-product stock codes", ~df.StockCode.str.match(r"^\d{5}", na=False), "postage, manual adjustments, fees, discounts, samples, vouchers")
step("unit price <= 0", df.UnitPrice <= 0, "free items / stock adjustments, would distort revenue")
df["is_cancel"] = df.InvoiceNo.str.startswith("C")
step("negative quantity that is not a cancellation", (df.Quantity < 0) & ~df.is_cancel, "stock write-offs, not customer behaviour")
step("cancellation with positive quantity", df.is_cancel & (df.Quantity > 0), "inconsistent rows")

df["invoice_ts"] = pd.to_datetime(df.InvoiceDate, format="%m/%d/%Y %H:%M")
df["revenue"] = (df.Quantity * df.UnitPrice).round(2)
df = df.rename(columns={"InvoiceNo": "invoice_no", "StockCode": "stock_code", "Description": "description", "Quantity": "quantity",
                        "UnitPrice": "unit_price", "CustomerID": "customer_id", "Country": "country"})
df["customer_id"] = df.customer_id.astype("Int64")
df["description"] = df.description.str.strip()
df = df.sort_values(["invoice_ts", "invoice_no", "stock_code"]).reset_index(drop=True)

# flag sales lines that were later reversed by an identical cancellation (same customer, product and quantity within 90 days).
pos = df[~df.is_cancel & df.customer_id.notna()][["invoice_ts", "customer_id", "stock_code", "quantity"]].rename(columns={"quantity": "qty_abs"})
pos["pos_row"] = pos.index
neg = df[df.is_cancel & df.customer_id.notna()][["invoice_ts", "customer_id", "stock_code", "quantity"]].copy(); neg["qty_abs"] = -neg.quantity
m = pd.merge_asof(neg.sort_values("invoice_ts").drop(columns="quantity"), pos.sort_values("invoice_ts"), on="invoice_ts",
                  by=["customer_id", "stock_code", "qty_abs"], direction="backward", tolerance=pd.Timedelta("90D"))
df["is_reversed"] = df.index.isin(m.pos_row.dropna().astype(int))
log.append(("flag: sales lines later fully reversed", 0, len(df), f"{int(df.is_reversed.sum()):,} lines (GBP {df.loc[df.is_reversed,'revenue'].sum():,.0f}) matched to a cancellation - flagged, not removed"))

out = df[["invoice_no", "stock_code", "description", "quantity", "invoice_ts", "unit_price", "customer_id", "country", "revenue", "is_cancel", "is_reversed"]].copy()
out.insert(0, "line_id", np.arange(1, len(out) + 1)); out["invoice_ts"] = out.invoice_ts.dt.strftime("%Y-%m-%d %H:%M:%S")
out["is_cancel"] = out.is_cancel.astype(int); out["is_reversed"] = out.is_reversed.astype(int)
if DB.exists(): DB.unlink()
con = sqlite3.connect(DB)
out.to_sql("transactions", con, index=False)
pd.DataFrame(log, columns=["step", "rows_removed", "rows_remaining", "note"]).to_sql("cleaning_log", con, index=False)
con.executescript("CREATE INDEX ix_tx_cust ON transactions(customer_id); CREATE INDEX ix_tx_ts ON transactions(invoice_ts);"
                  "CREATE INDEX ix_tx_inv ON transactions(invoice_no); CREATE INDEX ix_tx_stock ON transactions(stock_code);")
con.commit()
for r in con.execute("select step, rows_removed, rows_remaining from cleaning_log"): print(r)
print("transactions:", con.execute("select count(*) from transactions").fetchone()[0], "| customers:", con.execute("select count(distinct customer_id) from transactions").fetchone()[0])
con.close()
