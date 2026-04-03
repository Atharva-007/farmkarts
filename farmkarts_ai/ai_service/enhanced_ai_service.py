"""
Enhanced AI Service for FarmKart
Supports Ollama and Vertex AI (Claude) with optimized prompting
"""

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests
import json
import os
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
import asyncio
import time
from generator import get_generator, detect_farming_context

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="FarmKart Enhanced AI Service",
    description="Agricultural AI Assistant powered by Vertex AI and Ollama",
    version="2.1.0"
)

# Add CORS middleware
app.app_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AI_INTERNAL_KEY = os.getenv("AI_INTERNAL_KEY", "farmkart_internal_2024")

class AskRequest(BaseModel):
    query: str
    user_id: Optional[str] = None
    language: str = "en"
    context: Optional[str] = None

class AskResponse(BaseModel):
    answer: str
    confidence: float
    sources: List[str]
    model: str
    retrieval_count: int
    processing_time: float
    timestamp: str

class HealthResponse(BaseModel):
    status: str
    provider: str
    available: bool
    timestamp: str
    version: str

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    generator = get_generator()
    available = await generator.check_availability()
    provider_name = "VertexAI" if os.getenv("CLAUDE_CODE_USE_VERTEX") == "1" else "Ollama"
    
    return HealthResponse(
        status="healthy" if available else "degraded",
        provider=provider_name,
        available=available,
        timestamp=datetime.utcnow().isoformat(),
        version="2.1.0"
    )

@app.post("/ask", response_model=AskResponse)
async def ask_endpoint(payload: AskRequest, x_api_key: str = Header(None)):
    """Enhanced AI query endpoint with Vertex AI and Ollama support"""
    
    # Validate API key
    if x_api_key != AI_INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    start_time = time.time()
    generator = get_generator()
    
    try:
        # Detect context if not provided
        query_context = payload.context or detect_farming_context(payload.query)
        
        # Generate response
        # In a real RAG system, we would retrieve chunks here. 
        # For now, we pass an empty list or the query context as a 'chunk'
        context_chunks = [f"Focus on {query_context} in the context of Indian agriculture."]
        
        result = await generator.generate_response(
            payload.query,
            context_chunks,
            payload.language
        )
        
        processing_time = time.time() - start_time
        
        return AskResponse(
            answer=result["answer"],
            confidence=result["confidence"],
            sources=["FarmKart AI Expert", "Agricultural Knowledge Base"],
            model=result["model"],
            retrieval_count=len(context_chunks),
            processing_time=processing_time,
            timestamp=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Error processing query: {e}")
        processing_time = time.time() - start_time
        
        return AskResponse(
            answer="I apologize, but I'm experiencing technical difficulties. Please try again later or consult with local agricultural experts.",
            confidence=0.0,
            sources=[],
            model="error_fallback",
            retrieval_count=0,
            processing_time=processing_time,
            timestamp=datetime.utcnow().isoformat()
        )

@app.get("/stats")
async def get_stats():
    """Get service statistics"""
    generator = get_generator()
    available = await generator.check_availability()
    use_vertex = os.getenv("CLAUDE_CODE_USE_VERTEX") == "1"
    
    return {
        "service_status": "healthy" if available else "degraded",
        "provider": "Vertex AI (Claude)" if use_vertex else "Ollama (Phi3)",
        "available": available,
        "features": [
            "Vertex AI integration",
            "Ollama fallback support",
            "Multi-language support",
            "Context-aware responses"
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    print("="*50)
    print("FarmKart Enhanced AI Service v2.1.0")
    print("="*50)
    
    use_vertex = os.getenv("CLAUDE_CODE_USE_VERTEX") == "1"
    if use_vertex:
        print(f"Provider: Vertex AI (Claude)")
        print(f"Project: {os.getenv('ANTHROPIC_VERTEX_PROJECT_ID')}")
        print(f"Region: {os.getenv('CLOUD_ML_REGION', 'us-east5')}")
    else:
        print(f"Provider: Ollama (Phi3)")
        print(f"Ollama URL: http://localhost:11434")
        
    print("="*50)
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
