"""Re-downloads the public UCI 'Online Retail' data (CSV copy hosted on GitHub) into data/online_retail_raw.csv.gz.
The compressed file is already included in the repo, so you only need this if you want to refresh it.
Usage:  python src/download_data.py
"""
import gzip, shutil, urllib.request
from pathlib import Path

URL = "https://raw.githubusercontent.com/databricks/Spark-The-Definitive-Guide/master/data/retail-data/all/online-retail-dataset.csv"
OUT = Path(__file__).resolve().parents[1] / "data" / "online_retail_raw.csv.gz"
OUT.parent.mkdir(parents=True, exist_ok=True)
tmp = OUT.with_suffix(".csv")
urllib.request.urlretrieve(URL, tmp)
with open(tmp, "rb") as f, gzip.open(OUT, "wb") as g:
    shutil.copyfileobj(f, g)
tmp.unlink()
print(f"saved {OUT} ({OUT.stat().st_size/1e6:.1f} MB)")
