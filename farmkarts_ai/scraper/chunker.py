# chunker.py
# more advanced chunker splitting into sentences (if you want NLP splitting)
import nltk
nltk.download('punkt')
from nltk.tokenize import sent_tokenize

def advanced_chunk(text, max_sent=20):
    sents = sent_tokenize(text)
    chunks, cur = [], []
    for s in sents:
        cur.append(s)
        if len(cur) >= max_sent:
            chunks.append(" ".join(cur))
            cur = []
    if cur:
        chunks.append(" ".join(cur))
    return chunks
