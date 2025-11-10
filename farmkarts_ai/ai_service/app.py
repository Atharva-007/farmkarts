# app.py
from fastapi import FastAPI, Request, Header, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import logging
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any

# Import the comprehensive RAG pipeline
from rag_pipeline import RAGPipeline
from embeddings import EmbeddingService
from generator import ResponseGenerator
from index_store import IndexStore
from ingest_api import router as ingest_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment configuration
AI_INTERNAL_KEY = os.getenv("AI_INTERNAL_KEY", "REPLACE_ME")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

# Initialize FastAPI app
app = FastAPI(
    title="FarmKart AI RAG Service",
    description="Advanced Agricultural AI Assistant with RAG Pipeline",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global RAG pipeline instance
rag_pipeline: Optional[RAGPipeline] = None

# Request/Response models
class AskRequest(BaseModel):
    query: str
    user_id: Optional[str] = None
    language: str = "en"
    context: Optional[str] = None

class AskResponse(BaseModel):
    answer: str
    confidence: float
    sources: list
    model: str
    retrieval_count: int
    processing_time: float
    timestamp: str

class HealthResponse(BaseModel):
    status: str
    pipeline_initialized: bool
    timestamp: str
    version: str

@app.on_event("startup")
async def startup_event():
    """Initialize the RAG pipeline on startup"""
    global rag_pipeline
    try:
        logger.info("Starting FarmKart AI Service...")
        
        # Initialize components
        embedding_service = EmbeddingService()
        response_generator = ResponseGenerator()
        index_store = IndexStore()
        
        # Initialize RAG pipeline
        rag_pipeline = RAGPipeline(
            embedding_service=embedding_service,
            response_generator=response_generator,
            index_store=index_store,
            similarity_threshold=0.3,
            max_context_chunks=5
        )
        
        # Initialize the pipeline
        await rag_pipeline.initialize()
        
        logger.info("FarmKart AI Service started successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize RAG pipeline: {e}")
        # Don't fail startup, allow fallback responses
        rag_pipeline = None

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy" if rag_pipeline and rag_pipeline.is_initialized else "degraded",
        pipeline_initialized=rag_pipeline.is_initialized if rag_pipeline else False,
        timestamp=datetime.utcnow().isoformat(),
        version="2.0.0"
    )

@app.get("/stats")
async def get_stats(x_api_key: str = Header(None)):
    """Get pipeline statistics"""
    if x_api_key != AI_INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if not rag_pipeline:
        raise HTTPException(status_code=503, detail="Pipeline not initialized")
    
    return rag_pipeline.get_pipeline_stats()

@app.post("/ask", response_model=AskResponse)
async def ask_endpoint(payload: AskRequest, x_api_key: str = Header(None)):
    """Main AI query endpoint"""
    # Protect this endpoint
    if x_api_key != AI_INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if not rag_pipeline:
        raise HTTPException(status_code=503, detail="AI service not available")
    
    try:
        start_time = datetime.utcnow()
        
        # Generate response using RAG pipeline
        result = await rag_pipeline.generate_response(
            question=payload.query,
            context=payload.context,
            language=payload.language
        )
        
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        result["processing_time"] = processing_time
        result["timestamp"] = datetime.utcnow().isoformat()
        
        # Log query for monitoring (optional)
        if payload.user_id:
            logger.info(f"Query from user {payload.user_id}: {payload.query[:100]}...")
        
        return AskResponse(**result)
        
    except Exception as e:
        logger.error(f"Error processing query: {e}")
        # Return fallback response
        return AskResponse(
            answer="I apologize, but I'm experiencing technical difficulties. Please try again later.",
            confidence=0.0,
            sources=[],
            model="fallback",
            retrieval_count=0,
            processing_time=0.0,
            timestamp=datetime.utcnow().isoformat()
        )

@app.post("/admin/update-knowledge")
async def update_knowledge_base(
    background_tasks: BackgroundTasks,
    x_api_key: str = Header(None)
):
    """Update knowledge base in background"""
    if x_api_key != AI_INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if not rag_pipeline:
        raise HTTPException(status_code=503, detail="Pipeline not initialized")
    
    background_tasks.add_task(rag_pipeline.update_knowledge_base)
    return {"message": "Knowledge base update started in background"}

# Include admin routes for data ingestion
app.include_router(ingest_router, prefix="/admin")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
