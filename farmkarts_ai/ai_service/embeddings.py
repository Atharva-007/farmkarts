"""
Embedding Service for FarmKart AI
Handles text embeddings using sentence transformers
"""

from sentence_transformers import SentenceTransformer
import numpy as np
import logging
import re
from typing import List, Union
import os

logger = logging.getLogger(__name__)

class EmbeddingService:
    """Service for generating text embeddings"""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        """
        Initialize embedding service
        
        Args:
            model_name: Name of the sentence transformer model
        """
        self.model_name = model_name
        self._model = None
        self._dimension = None
        
    def get_model(self):
        """Lazy load the embedding model"""
        if self._model is None:
            logger.info(f"Loading embedding model: {self.model_name}")
            try:
                self._model = SentenceTransformer(self.model_name)
                self._dimension = self._model.get_sentence_embedding_dimension()
                logger.info(f"Model loaded successfully. Embedding dimension: {self._dimension}")
            except Exception as e:
                logger.error(f"Failed to load embedding model: {e}")
                raise
        return self._model
    
    def get_embedding_dimension(self) -> int:
        """Get the embedding dimension"""
        if self._dimension is None:
            model = self.get_model()
            self._dimension = model.get_sentence_embedding_dimension()
        return self._dimension
    
    def preprocess_text(self, text: str) -> str:
        """
        Preprocess text before embedding
        
        Args:
            text: Input text
            
        Returns:
            Cleaned text
        """
        if not text:
            return ""
        
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove special characters but keep punctuation
        text = re.sub(r'[^\w\s\.,!?;:()\-]', '', text)
        
        # Trim and return
        return text.strip()
    
    def encode(self, texts: Union[str, List[str]], show_progress: bool = False) -> np.ndarray:
        """
        Generate embeddings for text(s)
        
        Args:
            texts: Single text string or list of texts
            show_progress: Show progress bar for batch encoding
            
        Returns:
            Numpy array of embeddings (shape: [n, dimension])
        """
        try:
            model = self.get_model()
            
            # Handle single text
            if isinstance(texts, str):
                texts = [texts]
            
            # Preprocess texts
            processed_texts = [self.preprocess_text(text) for text in texts]
            
            # Generate embeddings
            embeddings = model.encode(
                processed_texts,
                show_progress_bar=show_progress,
                convert_to_numpy=True,
                normalize_embeddings=True  # Normalize for better similarity search
            )
            
            return embeddings.astype(np.float32)
            
        except Exception as e:
            logger.error(f"Error generating embeddings: {e}")
            raise
    
    def encode_single(self, text: str) -> np.ndarray:
        """
        Generate embedding for a single text
        
        Args:
            text: Input text
            
        Returns:
            1D numpy array of embedding
        """
        embeddings = self.encode([text])
        return embeddings[0]
    
    def compute_similarity(self, emb1: np.ndarray, emb2: np.ndarray) -> float:
        """
        Compute cosine similarity between two embeddings
        
        Args:
            emb1: First embedding
            emb2: Second embedding
            
        Returns:
            Similarity score (0-1)
        """
        try:
            # Ensure embeddings are normalized
            emb1_norm = emb1 / np.linalg.norm(emb1)
            emb2_norm = emb2 / np.linalg.norm(emb2)
            
            # Compute cosine similarity
            similarity = np.dot(emb1_norm, emb2_norm)
            
            # Convert to 0-1 range
            return (similarity + 1) / 2
            
        except Exception as e:
            logger.error(f"Error computing similarity: {e}")
            return 0.0

# Legacy functions for backward compatibility
_global_service = None

def get_embedding_service():
    """Get global embedding service instance"""
    global _global_service
    if _global_service is None:
        _global_service = EmbeddingService()
    return _global_service

def embed_texts(texts: List[str]) -> np.ndarray:
    """Legacy function - embed multiple texts"""
    service = get_embedding_service()
    return service.encode(texts)

def embed_text(text: str) -> np.ndarray:
    """Legacy function - embed single text"""
    service = get_embedding_service()
    return service.encode_single(text)
