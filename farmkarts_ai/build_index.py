#!/usr/bin/env python3
"""
Build FAISS Index for FarmKart AI
Processes corpus.jsonl and creates FAISS index with metadata
"""

import json
import os
import sys
import logging
from pathlib import Path

# Add ai_service to path
sys.path.append(str(Path(__file__).parent / "ai_service"))

from embeddings import EmbeddingService
from index_store import IndexStore

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def build_index_from_corpus(
    corpus_file: str = "ai_service/corpus.jsonl",
    index_path: str = "ai_service/faiss_index.bin",
    meta_path: str = "ai_service/faiss_meta.json",
    embedding_model: str = "all-MiniLM-L6-v2"
):
    """
    Build FAISS index from corpus file
    
    Args:
        corpus_file: Path to JSONL corpus file
        index_path: Output path for FAISS index
        meta_path: Output path for metadata JSON
        embedding_model: Sentence transformer model name
    """
    
    try:
        logger.info("Starting index build process...")
        
        # Check if corpus file exists
        if not os.path.exists(corpus_file):
            logger.error(f"Corpus file not found: {corpus_file}")
            return False
        
        # Initialize services
        logger.info(f"Initializing embedding service with model: {embedding_model}")
        embedding_service = EmbeddingService(model_name=embedding_model)
        
        logger.info("Initializing index store...")
        index_store = IndexStore(index_path=index_path, meta_path=meta_path)
        
        # Load corpus data
        logger.info(f"Loading corpus from: {corpus_file}")
        documents = []
        texts = []
        
        with open(corpus_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                try:
                    obj = json.loads(line.strip())
                    
                    # Extract text and metadata
                    text = obj.get("text", "").strip()
                    if not text:
                        logger.warning(f"Empty text at line {line_num}, skipping")
                        continue
                    
                    texts.append(text)
                    
                    # Prepare document metadata
                    doc_metadata = {
                        "content": text,
                        "source": obj.get("source", "unknown"),
                        "title": obj.get("title", ""),
                        "category": obj.get("category", "general"),
                        "language": obj.get("language", "en"),
                        "url": obj.get("url", ""),
                        "line_number": line_num
                    }
                    
                    # Add any additional metadata
                    for key, value in obj.items():
                        if key not in ["text", "source", "title", "category", "language", "url"]:
                            doc_metadata[key] = value
                    
                    documents.append(doc_metadata)
                    
                except json.JSONDecodeError as e:
                    logger.error(f"JSON decode error at line {line_num}: {e}")
                    continue
                except Exception as e:
                    logger.error(f"Error processing line {line_num}: {e}")
                    continue
        
        if not texts:
            logger.error("No valid documents found in corpus file")
            return False
        
        logger.info(f"Loaded {len(texts)} documents from corpus")
        
        # Generate embeddings
        logger.info("Generating embeddings...")
        embeddings = embedding_service.encode(texts, show_progress=True)
        logger.info(f"Generated embeddings with shape: {embeddings.shape}")
        
        # Clear existing index and add documents
        logger.info("Building index...")
        index_store.clear_index()  # Start fresh
        index_store.add_documents(embeddings, documents)
        
        # Save index to disk
        logger.info("Saving index to disk...")
        index_store.save_index()
        
        # Get final statistics
        stats = await_sync(index_store.get_statistics())
        logger.info(f"Index build complete!")
        logger.info(f"Total documents: {stats.get('total_documents', 0)}")
        logger.info(f"Index size: {stats.get('index_size', 0)}")
        logger.info(f"Embedding dimension: {stats.get('embedding_dimension', 0)}")
        logger.info(f"Index file: {index_path}")
        logger.info(f"Metadata file: {meta_path}")
        
        return True
        
    except Exception as e:
        logger.error(f"Error building index: {e}")
        return False

def await_sync(coro):
    """Run async function synchronously"""
    import asyncio
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Build FAISS index for FarmKart AI")
    parser.add_argument(
        "--corpus", 
        default="ai_service/corpus.jsonl",
        help="Path to corpus JSONL file"
    )
    parser.add_argument(
        "--index-path",
        default="ai_service/faiss_index.bin", 
        help="Output path for FAISS index"
    )
    parser.add_argument(
        "--meta-path",
        default="ai_service/faiss_meta.json",
        help="Output path for metadata JSON"
    )
    parser.add_argument(
        "--model",
        default="all-MiniLM-L6-v2",
        help="Sentence transformer model name"
    )
    
    args = parser.parse_args()
    
    success = build_index_from_corpus(
        corpus_file=args.corpus,
        index_path=args.index_path,
        meta_path=args.meta_path,
        embedding_model=args.model
    )
    
    if success:
        logger.info("Index build completed successfully!")
        sys.exit(0)
    else:
        logger.error("Index build failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
