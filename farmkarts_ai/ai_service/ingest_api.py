"""
Ingest API for FarmKart AI
Handles document ingestion and knowledge base management
"""

from fastapi import APIRouter, Header, HTTPException, BackgroundTasks, File, UploadFile
from pydantic import BaseModel, validator
from typing import List, Optional, Dict, Any
import os
import json
import logging
from datetime import datetime
import pdfplumber
import io

from embeddings import EmbeddingService
from index_store import IndexStore

logger = logging.getLogger(__name__)

router = APIRouter()

# API Key from environment
API_KEY = os.getenv("AI_INTERNAL_KEY", "farmkart_ai_secret_key_2024")

class DocumentChunk(BaseModel):
    text: str
    source: str
    url: Optional[str] = None
    title: Optional[str] = ""
    category: Optional[str] = "general"
    language: str = "en"
    metadata: Optional[Dict[str, Any]] = {}
    
    @validator('text')
    def text_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('Text content cannot be empty')
        return v.strip()
    
    @validator('source')
    def source_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('Source cannot be empty')
        return v.strip()

class IngestRequest(BaseModel):
    chunks: List[DocumentChunk]
    overwrite: bool = False
    
    @validator('chunks')
    def chunks_must_not_be_empty(cls, v):
        if not v:
            raise ValueError('Chunks list cannot be empty')
        return v

class IngestResponse(BaseModel):
    status: str
    ingested_count: int
    failed_count: int
    message: str
    timestamp: str

class DocumentUpload(BaseModel):
    title: str
    source: str
    category: str = "general"
    language: str = "en"
    metadata: Optional[Dict[str, Any]] = {}

# Global services
embedding_service = None
index_store = None

def get_services():
    """Get or initialize services"""
    global embedding_service, index_store
    if embedding_service is None:
        embedding_service = EmbeddingService()
    if index_store is None:
        index_store = IndexStore()
        index_store.load_index()
    return embedding_service, index_store

@router.post("/ingest", response_model=IngestResponse)
async def ingest_documents(
    request: IngestRequest,
    background_tasks: BackgroundTasks,
    x_api_key: str = Header(None)
):
    """Ingest document chunks into the knowledge base"""
    
    # Validate API key
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        emb_service, idx_store = get_services()
        
        ingested_count = 0
        failed_count = 0
        
        # Process chunks in batches for efficiency
        batch_size = 10
        chunks_data = request.chunks
        
        for i in range(0, len(chunks_data), batch_size):
            batch = chunks_data[i:i + batch_size]
            
            # Prepare texts for embedding
            texts = [chunk.text for chunk in batch]
            
            # Generate embeddings
            try:
                embeddings = emb_service.encode(texts)
                
                # Prepare document metadata
                documents = []
                for j, chunk in enumerate(batch):
                    doc_metadata = {
                        "content": chunk.text,
                        "source": chunk.source,
                        "url": chunk.url,
                        "title": chunk.title,
                        "category": chunk.category,
                        "language": chunk.language,
                        "ingested_at": datetime.utcnow().isoformat()
                    }
                    
                    # Add custom metadata
                    if chunk.metadata:
                        doc_metadata.update(chunk.metadata)
                    
                    documents.append(doc_metadata)
                
                # Add to index
                idx_store.add_documents(embeddings, documents)
                ingested_count += len(batch)
                
            except Exception as e:
                logger.error(f"Error processing batch {i//batch_size + 1}: {e}")
                failed_count += len(batch)
        
        # Save index in background
        background_tasks.add_task(idx_store.save_index)
        
        return IngestResponse(
            status="success" if failed_count == 0 else "partial_success",
            ingested_count=ingested_count,
            failed_count=failed_count,
            message=f"Successfully ingested {ingested_count} chunks" + 
                   (f", {failed_count} failed" if failed_count > 0 else ""),
            timestamp=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Error in document ingestion: {e}")
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {str(e)}")

@router.post("/ingest/pdf")
async def ingest_pdf(
    file: UploadFile = File(...),
    document_info: str = None,  # JSON string of DocumentUpload
    x_api_key: str = Header(None)
):
    """Ingest PDF document"""
    
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")
    
    try:
        # Parse document info
        doc_info = DocumentUpload(
            title=file.filename,
            source="pdf_upload",
            category="general"
        )
        
        if document_info:
            try:
                info_dict = json.loads(document_info)
                doc_info = DocumentUpload(**info_dict)
            except Exception as e:
                logger.warning(f"Failed to parse document info: {e}")
        
        # Read PDF content
        pdf_content = await file.read()
        text_content = ""
        
        with pdfplumber.open(io.BytesIO(pdf_content)) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    text_content += page_text + "\n\n"
        
        if not text_content.strip():
            raise HTTPException(status_code=400, detail="No text content found in PDF")
        
        # Chunk the text
        chunks = _chunk_text(text_content, chunk_size=500, chunk_overlap=50)
        
        # Create document chunks
        document_chunks = []
        for i, chunk in enumerate(chunks):
            chunk_data = DocumentChunk(
                text=chunk,
                source=doc_info.source,
                title=f"{doc_info.title} (Part {i+1})",
                category=doc_info.category,
                language=doc_info.language,
                metadata={
                    "file_name": file.filename,
                    "chunk_index": i,
                    "total_chunks": len(chunks),
                    **doc_info.metadata
                }
            )
            document_chunks.append(chunk_data)
        
        # Ingest chunks
        ingest_request = IngestRequest(chunks=document_chunks)
        return await ingest_documents(ingest_request, BackgroundTasks(), x_api_key)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing PDF: {e}")
        raise HTTPException(status_code=500, detail=f"PDF processing failed: {str(e)}")

@router.get("/stats")
async def get_knowledge_base_stats(x_api_key: str = Header(None)):
    """Get knowledge base statistics"""
    
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        _, idx_store = get_services()
        stats = await idx_store.get_statistics()
        return stats
        
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")

@router.delete("/clear")
async def clear_knowledge_base(x_api_key: str = Header(None)):
    """Clear the entire knowledge base"""
    
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        _, idx_store = get_services()
        idx_store.clear_index()
        
        return {
            "status": "success",
            "message": "Knowledge base cleared successfully",
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error clearing knowledge base: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to clear knowledge base: {str(e)}")

@router.post("/search")
async def search_knowledge_base(
    query: str,
    k: int = 5,
    threshold: float = 0.3,
    x_api_key: str = Header(None)
):
    """Search the knowledge base"""
    
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        emb_service, idx_store = get_services()
        
        # Generate query embedding
        query_embedding = emb_service.encode_single(query)
        
        # Search index
        results = idx_store.search(query_embedding, k=k, score_threshold=threshold)
        
        return {
            "query": query,
            "results": results,
            "count": len(results),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error searching knowledge base: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

def _chunk_text(text: str, chunk_size: int = 500, chunk_overlap: int = 50) -> List[str]:
    """Split text into overlapping chunks"""
    words = text.split()
    chunks = []
    
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        
        if end >= len(words):
            break
        start = end - chunk_overlap
    
    return chunks


# Legacy function for backward compatibility
async def ingest_chunks(chunks: List[str], metas: List[Dict[str, Any]]):
    """Legacy function for ingesting chunks"""
    try:
        emb_service, idx_store = get_services()
        
        # Generate embeddings
        embeddings = emb_service.encode(chunks)
        
        # Prepare documents
        documents = []
        for i, (chunk, meta) in enumerate(zip(chunks, metas)):
            doc_metadata = {
                "content": chunk,
                "ingested_at": datetime.utcnow().isoformat(),
                **meta
            }
            documents.append(doc_metadata)
        
        # Add to index
        idx_store.add_documents(embeddings, documents)
        idx_store.save_index()
        
        logger.info(f"Legacy ingestion: Added {len(chunks)} chunks")
        
    except Exception as e:
        logger.error(f"Error in legacy ingestion: {e}")
        raise
