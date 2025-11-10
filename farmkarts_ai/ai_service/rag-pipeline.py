# rag_pipeline.py
from embeddings import embed_text, embed_texts
from index_store import search, add_documents
from generator import answer_query
import numpy as np

def ingest_chunks(chunks: list, sources_meta: list):
    """
    chunks: list of text chunk strings
    sources_meta: list of dicts for each chunk (source, url, title, lang)
    """
    embs = embed_texts(chunks)
    add_documents(chunks, sources_meta, embs)

def ask(query: str, k: int = 5, language: str = "en"):
    q_emb = embed_text(query)
    results = search(q_emb, k)
    retrieved_texts = [r['text'] + f"\n\n[source:{r['source'].get('source','unknown')} url:{r['source'].get('url','')}]"
                       for r in results]
    answer = answer_query(query, retrieved_texts, language=language)
    return {"answer": answer, "sources": [r['source'] for r in results]}
