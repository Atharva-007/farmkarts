# scrape_sites.py
import requests, time, os, json, re
from bs4 import BeautifulSoup
from urllib.parse import urljoin
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()
DATA_DIR = os.getenv("DATA_DIR", "../ai_service/data")
os.makedirs(DATA_DIR, exist_ok=True)

# Small set of trusted sources (expand as you go)
SOURCES = [
    {"name":"ICAR","url":"https://icar.org.in/"},
    {"name":"Agmarknet","url":"https://agmarknet.gov.in/"},
    {"name":"AgriDept","url":"https://agricoop.gov.in/"},
    {"name":"Mahabeej","url":"https://www.mahabeej.com/"},
]

def fetch_text_from_url(url, session=None):
    try:
        r = (session or requests).get(url, timeout=20)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "lxml")
        # remove scripts/styles
        for s in soup(["script", "style", "noscript"]):
            s.decompose()
        paragraphs = [p.get_text(separator=' ', strip=True) for p in soup.find_all(['p','li'])]
        text = "\n".join([p for p in paragraphs if len(p) > 50])
        return text
    except Exception as e:
        print("fetch error", url, e)
        return ""

def sanitize_filename(name):
    return re.sub(r'[^a-zA-Z0-9_\-\.]', '_', name)[:200]

def main():
    out_manifest = []
    for s in SOURCES:
        print("Scraping", s["name"], s["url"])
        txt = fetch_text_from_url(s["url"])
        if txt:
            fname = sanitize_filename(f"{s['name']}_{datetime.utcnow().isoformat()}.txt")
            path = os.path.join(DATA_DIR, fname)
            with open(path, "w", encoding="utf-8") as f:
                f.write(txt)
            out_manifest.append({"source": s["name"], "url": s["url"], "path": path, "fetched_at": datetime.utcnow().isoformat()})
        time.sleep(2)
    # write manifest
    manifest_path = os.path.join(DATA_DIR, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(out_manifest, f, ensure_ascii=False, indent=2)
    print("Done scraping. Saved to", DATA_DIR)

if __name__ == "__main__":
    main()
