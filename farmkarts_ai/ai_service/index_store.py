"""
Index Store for FarmKart AI
Manages FAISS vector index and document metadata
"""

import faiss
import numpy as np
import os
import json
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

class IndexStore:
    """Service for managing vector index and document storage"""
    
    def __init__(
        self,
        index_path: str = "faiss_index.bin",
        meta_path: str = "faiss_meta.json",
        embedding_dim: int = 384
    ):
        """
        Initialize index store
        
        Args:
            index_path: Path to FAISS index file
            meta_path: Path to metadata JSON file
            embedding_dim: Dimension of embeddings (384 for all-MiniLM-L6-v2)
        """
        self.index_path = index_path
        self.meta_path = meta_path
        self.embedding_dim = embedding_dim
        
        self._index = None
        self._metadata = {"documents": [], "created_at": None, "last_updated": None}
        self._is_loaded = False
    
    def load_index(self) -> bool:
        """Load existing index and metadata"""
        try:
            # Load FAISS index
            if os.path.exists(self.index_path):
                self._index = faiss.read_index(self.index_path)
                logger.info(f"Loaded FAISS index from {self.index_path}")
            else:
                self._index = faiss.IndexFlatL2(self.embedding_dim)
                logger.info(f"Created new FAISS index with dimension {self.embedding_dim}")
            
            # Load metadata
            if os.path.exists(self.meta_path):
                with open(self.meta_path, 'r', encoding='utf-8') as f:
                    self._metadata = json.load(f)
                logger.info(f"Loaded metadata for {len(self._metadata['documents'])} documents")
            else:
                self._metadata = {
                    "documents": [],
                    "created_at": datetime.utcnow().isoformat(),
                    "last_updated": datetime.utcnow().isoformat()
                }
                logger.info("Created new metadata store")
            
            self._is_loaded = True
            return True
            
        except Exception as e:
            logger.error(f"Error loading index: {e}")
            # Create new index if loading fails
            self._index = faiss.IndexFlatL2(self.embedding_dim)
            self._metadata = {
                "documents": [],
                "created_at": datetime.utcnow().isoformat(),
                "last_updated": datetime.utcnow().isoformat()
            }
            self._is_loaded = True
            return False
    
    def save_index(self):
        """Save index and metadata to disk"""
        try:
            if self._index is not None:
                # Save FAISS index
                faiss.write_index(self._index, self.index_path)
                
                # Update metadata timestamp
                self._metadata["last_updated"] = datetime.utcnow().isoformat()
                
                # Save metadata
                with open(self.meta_path, 'w', encoding='utf-8') as f:
                    json.dump(self._metadata, f, ensure_ascii=False, indent=2)
                
                logger.info(f"Saved index and metadata to disk")
            
        except Exception as e:
            logger.error(f"Error saving index: {e}")
            raise
    
    def add_documents(self, embeddings: np.ndarray, documents: List[Dict[str, Any]]):
        """
        Add documents to the index
        
        Args:
            embeddings: Numpy array of embeddings (shape: [n, dim])
            documents: List of document metadata dictionaries
        """
        try:
            if not self._is_loaded:
                self.load_index()
            
            n_docs = embeddings.shape[0]
            if len(documents) != n_docs:
                raise ValueError(f"Number of embeddings ({n_docs}) must match number of documents ({len(documents)})")
            
            # Ensure embeddings are float32
            embeddings = embeddings.astype(np.float32)
            
            # Add to FAISS index
            self._index.add(embeddings)
            
            # Add to metadata
            for doc in documents:
                doc["doc_id"] = len(self._metadata["documents"])  # Assign sequential ID
                doc["added_at"] = datetime.utcnow().isoformat()
                self._metadata["documents"].append(doc)
            
            logger.info(f"Added {n_docs} documents to index")
            
        except Exception as e:
            logger.error(f"Error adding documents: {e}")
            raise
    
    def search(
        self,
        query_embedding: np.ndarray,
        k: int = 5,
        score_threshold: float = None
    ) -> List[Dict[str, Any]]:
        """
        Search for similar documents
        
        Args:
            query_embedding: Query embedding vector
            k: Number of results to return
            score_threshold: Minimum similarity score threshold
            
        Returns:
            List of search results with content, score, and metadata
        """
        try:
            if not self._is_loaded:
                self.load_index()
            
            if self._index.ntotal == 0:
                logger.info("Index is empty, returning no results")
                return []
            
            # Ensure query embedding is the right shape and type
            if query_embedding.ndim == 1:
                query_embedding = query_embedding.reshape(1, -1)
            query_embedding = query_embedding.astype(np.float32)
            
            # Search index
            scores, indices = self._index.search(query_embedding, min(k, self._index.ntotal))
            
            results = []
            for score, idx in zip(scores[0], indices[0]):
                if idx < 0:  # Invalid index
                    continue
                
                # Convert L2 distance to similarity score (0-1 range)
                # Lower L2 distance = higher similarity
                similarity = 1.0 / (1.0 + score)
                
                # Apply score threshold if specified
                if score_threshold is not None and similarity < score_threshold:
                    continue
                
                # Get document metadata
                if idx < len(self._metadata["documents"]):
                    doc_meta = self._metadata["documents"][idx]
                    results.append({
                        "content": doc_meta.get("content", ""),
                        "score": float(similarity),
                        "metadata": doc_meta,
                        "doc_id": idx
                    })
            
            logger.info(f"Found {len(results)} results for query")
            return results
            
        except Exception as e:
            logger.error(f"Error searching index: {e}")
            return []
    
    async def get_statistics(self) -> Dict[str, Any]:
        """Get index statistics"""
        try:
            if not self._is_loaded:
                self.load_index()
            
            return {
                "total_documents": len(self._metadata["documents"]) if self._metadata else 0,
                "index_size": self._index.ntotal if self._index else 0,
                "embedding_dimension": self.embedding_dim,
                "created_at": self._metadata.get("created_at"),
                "last_updated": self._metadata.get("last_updated"),
                "index_file_exists": os.path.exists(self.index_path),
                "metadata_file_exists": os.path.exists(self.meta_path),
                "is_loaded": self._is_loaded
            }
            
        except Exception as e:
            logger.error(f"Error getting statistics: {e}")
            return {"error": str(e)}
    
    def clear_index(self):
        """Clear all documents from index"""
        try:
            logger.info("Clearing index...")
            
            # Reset index
            self._index = faiss.IndexFlatL2(self.embedding_dim)
            
            # Reset metadata
            self._metadata = {
                "documents": [],
                "created_at": datetime.utcnow().isoformat(),
                "last_updated": datetime.utcnow().isoformat()
            }
            
            # Save empty index
            self.save_index()
            
            logger.info("Index cleared successfully")
            
        except Exception as e:
            logger.error(f"Error clearing index: {e}")
            raise


# Legacy functions for backward compatibility
_global_index_store = None

def get_index_store():
    """Get global index store instance"""
    global _global_index_store
    if _global_index_store is None:
        _global_index_store = IndexStore()
    return _global_index_store

def persist_index():
    """Legacy function - save index"""
    store = get_index_store()
    store.save_index()

def add_documents(docs: list, sources: list, embeddings: np.ndarray):
    """Legacy function - add documents"""
    store = get_index_store()
    documents = []
    for i, (doc, source) in enumerate(zip(docs, sources)):
        documents.append({
            "content": doc,
            "metadata": source if isinstance(source, dict) else {"source": source}
        })
    store.add_documents(embeddings, documents)

def search(query_emb, k=5):
    """Legacy function - search"""
    store = get_index_store()
    results = store.search(query_emb, k)
    # Convert to old format
    legacy_results = []
    for result in results:
        legacy_results.append({
            "score": result["score"],
            "text": result["content"],
            "source": result["metadata"]
        })
    return legacy_results
