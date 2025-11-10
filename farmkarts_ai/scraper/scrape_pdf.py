# scrape_pdf.py
import requests, os, io
import pdfplumber
from bs4 import BeautifulSoup
from urllib.parse import urljoin
from datetime import datetime

DATA_DIR = os.getenv("DATA_DIR", "../ai_service/data")
os.makedirs(DATA_DIR, exist_ok=True)

def extract_text_from_pdf_url(pdf_url):
    try:
        r = requests.get(pdf_url, timeout=20)
        r.raise_for_status()
        with io.BytesIO(r.content) as f:
            with pdfplumber.open(f) as pdf:
                pages = [p.extract_text() for p in pdf.pages if p.extract_text()]
                return "\n".join(pages)
    except Exception as e:
        print("pdf error", pdf_url, e)
        return ""

def scrape_pdf_links(page_url):
    r = requests.get(page_url, timeout=20)
    soup = BeautifulSoup(r.text, "lxml")
    links = [urljoin(page_url, a['href']) for a in soup.find_all('a', href=True) if a['href'].lower().endswith('.pdf')]
    return links

def main():
    # Example: government site with PDF resources
    pages = [
        "https://icar.org.in/publications",
        "https://agricoop.gov.in/en/publications"
    ]
    for p in pages:
        print("Scanning", p)
        pdfs = scrape_pdf_links(p)
        for pdf in pdfs:
            print("Downloading PDF", pdf)
            txt = extract_text_from_pdf_url(pdf)
            if txt:
                fname = f"pdf_{datetime.utcnow().isoformat()}.txt"
                with open(os.path.join(DATA_DIR, fname), "w", encoding="utf-8") as f:
                    f.write(txt)
    print("PDF scraping done.")
