# preprocess.py
import os, json, re
from pathlib import Path

DATA_DIR = os.getenv("DATA_DIR", "../ai_service/data")
OUT_FILE = os.getenv("CORPUS_FILE", "../ai_service/corpus.jsonl")
os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)

def chunk_text_simple(text, max_chars=1000, overlap=200):
    text = re.sub(r'\s+', ' ', text).strip()
    chunks = []
    start = 0
    while start < len(text):
        end = min(len(text), start + max_chars)
        chunks.append(text[start:end].strip())
        start = end - overlap
        if start < 0:
            start = 0
    return chunks

def main():
    files = [f for f in Path(DATA_DIR).glob("*.txt")]
    with open(OUT_FILE, "w", encoding="utf-8") as out:
        for file in files:
            txt = file.read_text(encoding='utf-8').strip()
            if len(txt) < 100: 
                continue
            chunks = chunk_text_simple(txt, max_chars=1200, overlap=200)
            for c in chunks:
                doc = {"source": file.name, "text": c}
                out.write(json.dumps(doc, ensure_ascii=False) + "\n")
    print("Corpus written to", OUT_FILE)

if __name__ == "__main__":
    main()
