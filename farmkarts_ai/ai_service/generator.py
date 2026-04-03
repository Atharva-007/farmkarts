"""
Response Generator for FarmKart AI
Handles AI response generation using Ollama, Vertex AI (Claude), or fallback responses
"""

import subprocess
import json
import os
import sys
import logging
import asyncio
from datetime import datetime
from typing import List, Dict, Any, Optional
import requests

# Conditional imports for Vertex AI
try:
    from anthropic import AnthropicVertex
    VERTEX_AVAILABLE = True
except ImportError:
    VERTEX_AVAILABLE = False

logger = logging.getLogger(__name__)

class BaseGenerator:
    """Base class for response generators"""
    def __init__(self):
        self.fallback_responses = {
            "general": "I'm here to help with agricultural questions. Could you please provide more specific details about your farming concern?",
            "soil": "For soil-related questions, I recommend testing your soil pH and consulting with local agricultural extension services.",
            "pest": "For pest management, consider integrated pest management (IPM) approaches and consult with local experts for region-specific advice.",
            "crop": "For crop-related questions, factors like local climate, soil conditions, and farming practices are important. Please consult local agricultural experts.",
            "weather": "Weather patterns vary by region. I recommend checking local weather services and agricultural meteorology departments.",
            "fertilizer": "Fertilizer recommendations depend on soil tests and crop requirements. Please consult agricultural extension services for soil testing."
        }

    def _build_prompt(self, question: str, context_chunks: List[str], language: str = "en") -> str:
        """Build prompt for AI model"""
        context = "\n\n---\n\n".join(context_chunks)
        
        language_instruction = ""
        if language == "hi":
            language_instruction = "Please respond in Hindi (हिन्दी में उत्तर दें)."
        elif language != "en":
            language_instruction = f"Please respond in {language} language."
        
        prompt = f"""You are FarmKart's agricultural expert assistant for Indian farmers.
Use ONLY the following context from trusted agricultural sources to answer the question.
Be concise, actionable, and safety-conscious in your response.

Context:
{context}

Question: {question}

{language_instruction}

Please provide:
1. A brief diagnosis or explanation (1-2 sentences)
2. 3-4 specific actionable steps (bullet points)
3. Important safety warnings (if applicable)
4. Mention the sources used

Keep language simple and practical for farmers. If the context doesn't contain enough information to answer safely, say "Based on the available information, I recommend consulting with a local agricultural expert for this specific concern."

Answer:"""
        return prompt

    def _generate_fallback_response(self, question: str, context_chunks: List[str]) -> str:
        """Generate rule-based fallback response"""
        try:
            question_lower = question.lower()
            if context_chunks:
                key_points = []
                for chunk in context_chunks[:3]:
                    if len(chunk) > 100:
                        sentences = chunk.split('.')
                        if sentences:
                            key_points.append(sentences[0].strip() + ".")
                
                if key_points:
                    response = f"Based on the available agricultural information:\n\n"
                    response += f"• {key_points[0]}\n"
                    if len(key_points) > 1:
                        response += f"• {key_points[1]}\n"
                    
                    response += f"\nFor your specific question about: '{question}'\n\n"
                    response += "I recommend:\n"
                    response += "• Consult with your local agricultural extension officer\n"
                    response += "• Consider soil testing if not done recently\n"
                    response += "• Follow integrated farming practices\n\n"
                    return response
            
            if any(word in question_lower for word in ["soil", "ph", "fertility", "nutrients"]):
                return self.fallback_responses["soil"]
            elif any(word in question_lower for word in ["pest", "insect", "disease", "fungus"]):
                return self.fallback_responses["pest"]
            elif any(word in question_lower for word in ["crop", "plant", "grow", "seed"]):
                return self.fallback_responses["crop"]
            elif any(word in question_lower for word in ["weather", "rain", "climate"]):
                return self.fallback_responses["weather"]
            elif any(word in question_lower for word in ["fertilizer", "manure", "compost"]):
                return self.fallback_responses["fertilizer"]
            else:
                return self.fallback_responses["general"]
        except Exception as e:
            logger.error(f"Error in fallback response generation: {e}")
            return self.fallback_responses["general"]

    def get_simple_fallback(self, question: str) -> str:
        """Get simple fallback response"""
        return "I apologize, but I'm currently unable to provide a detailed response. Please consult with local agricultural experts or extension services for assistance with your farming questions."

class ResponseGenerator(BaseGenerator):
    """Service for generating AI responses using Ollama"""
    
    def __init__(
        self,
        model_name: str = None,
        ollama_host: str = "localhost:11434",
        timeout: int = 60,
        max_tokens: int = 512
    ):
        super().__init__()
        self.model_name = model_name or os.getenv("OLLAMA_MODEL", "phi3:latest")
        self.ollama_host = ollama_host
        self.timeout = timeout
        self.max_tokens = max_tokens
        self.ollama_url = f"http://{ollama_host}"
    
    async def check_availability(self) -> bool:
        """Check if Ollama model is available"""
        try:
            response = requests.get(f"{self.ollama_url}/api/tags", timeout=5)
            if response.status_code == 200:
                models = response.json().get("models", [])
                model_names = [model["name"] for model in models]
                return self.model_name in model_names
            return False
        except Exception:
            return False
    
    async def generate_response(
        self,
        question: str,
        context_chunks: List[str],
        language: str = "en"
    ) -> Dict[str, Any]:
        start_time = datetime.utcnow()
        try:
            if await self.check_availability():
                prompt = self._build_prompt(question, context_chunks, language)
                payload = {
                    "model": self.model_name,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"num_predict": self.max_tokens, "temperature": 0.7}
                }
                response = requests.post(f"{self.ollama_url}/api/generate", json=payload, timeout=self.timeout)
                if response.status_code == 200:
                    answer = response.json().get("response", "").strip()
                    processing_time = (datetime.utcnow() - start_time).total_seconds()
                    return {
                        "answer": answer,
                        "confidence": 0.8,
                        "model": f"Ollama:{self.model_name}",
                        "processing_time": processing_time,
                        "timestamp": datetime.utcnow().isoformat()
                    }
            
            fallback_response = self._generate_fallback_response(question, context_chunks)
            return {
                "answer": fallback_response,
                "confidence": 0.6,
                "model": "fallback",
                "processing_time": (datetime.utcnow() - start_time).total_seconds(),
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            logger.error(f"Error in Ollama generation: {e}")
            return {
                "answer": self.get_simple_fallback(question),
                "confidence": 0.2,
                "model": "error_fallback",
                "processing_time": (datetime.utcnow() - start_time).total_seconds(),
                "timestamp": datetime.utcnow().isoformat()
            }

class VertexAIGenerator(BaseGenerator):
    """Service for generating AI responses using Google Vertex AI (Claude)"""
    
    def __init__(
        self,
        model_name: str = None,
        project_id: str = None,
        region: str = None,
        max_tokens: int = 1024
    ):
        super().__init__()
        self.model_name = model_name or os.getenv("ANTHROPIC_MODEL", "claude-3-5-sonnet-v2@20241022")
        self.project_id = project_id or os.getenv("ANTHROPIC_VERTEX_PROJECT_ID")
        self.region = region or os.getenv("CLOUD_ML_REGION", "us-east5")
        self.max_tokens = max_tokens
        
        if VERTEX_AVAILABLE and self.project_id:
            try:
                self.client = AnthropicVertex(project_id=self.project_id, region=self.region)
                self.available = True
            except Exception as e:
                logger.error(f"Failed to initialize Vertex AI client: {e}")
                self.available = False
        else:
            self.available = False
            if not VERTEX_AVAILABLE:
                logger.warning("Vertex AI (Anthropic) SDK not installed")
            if not self.project_id:
                logger.warning("ANTHROPIC_VERTEX_PROJECT_ID not set")

    async def check_availability(self) -> bool:
        return self.available

    async def generate_response(
        self,
        question: str,
        context_chunks: List[str],
        language: str = "en"
    ) -> Dict[str, Any]:
        start_time = datetime.utcnow()
        try:
            if self.available:
                prompt = self._build_prompt(question, context_chunks, language)
                
                # Run synchronous client call in a thread pool
                loop = asyncio.get_event_loop()
                response = await loop.run_in_executor(
                    None,
                    lambda: self.client.messages.create(
                        model=self.model_name,
                        max_tokens=self.max_tokens,
                        messages=[{"role": "user", "content": prompt}]
                    )
                )
                
                answer = response.content[0].text.strip()
                processing_time = (datetime.utcnow() - start_time).total_seconds()
                
                return {
                    "answer": answer,
                    "confidence": 0.95,
                    "model": f"VertexAI:{self.model_name}",
                    "processing_time": processing_time,
                    "timestamp": datetime.utcnow().isoformat()
                }
            
            fallback_response = self._generate_fallback_response(question, context_chunks)
            return {
                "answer": fallback_response,
                "confidence": 0.6,
                "model": "fallback",
                "processing_time": (datetime.utcnow() - start_time).total_seconds(),
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            logger.error(f"Error in Vertex AI generation: {e}")
            return {
                "answer": self.get_simple_fallback(question),
                "confidence": 0.2,
                "model": "error_fallback",
                "processing_time": (datetime.utcnow() - start_time).total_seconds(),
                "timestamp": datetime.utcnow().isoformat()
            }

def get_generator() -> BaseGenerator:
    """Factory function to get the configured generator"""
    use_vertex = os.getenv("CLAUDE_CODE_USE_VERTEX", "0") == "1"
    
    if use_vertex:
        logger.info("Using Vertex AI Generator")
        return VertexAIGenerator()
    else:
        logger.info("Using Ollama Generator")
        return ResponseGenerator()

# Legacy functions for backward compatibility
async def _async_answer_query(query: str, retrieved_texts: list, language: str = "en") -> str:
    generator = get_generator()
    result = await generator.generate_response(query, retrieved_texts, language)
    return result.get("answer", "Error generating response")

def answer_query(query: str, retrieved_texts: list, language: str = "en") -> str:
    """Legacy function - answer query"""
    try:
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(_async_answer_query(query, retrieved_texts, language))
    except Exception:
        # Fallback if loop is already running
        return "I apologize, but I'm currently experiencing technical difficulties. Please try again later."
