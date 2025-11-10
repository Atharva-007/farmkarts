"""
Response Generator for FarmKart AI
Handles AI response generation using Ollama or fallback responses
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

logger = logging.getLogger(__name__)

class ResponseGenerator:
    """Service for generating AI responses"""
    
    def __init__(
        self,
        model_name: str = None,
        ollama_host: str = "localhost:11434",
        timeout: int = 60,
        max_tokens: int = 512
    ):
        """
        Initialize response generator
        
        Args:
            model_name: Ollama model name
            ollama_host: Ollama server host
            timeout: Request timeout in seconds
            max_tokens: Maximum tokens in response
        """
        self.model_name = model_name or os.getenv("OLLAMA_MODEL", "phi3:latest")  # Updated to use phi3:latest
        self.ollama_host = ollama_host
        self.timeout = timeout
        self.max_tokens = max_tokens
        self.ollama_url = f"http://{ollama_host}"
        
        # Fallback responses for different scenarios
        self.fallback_responses = {
            "general": "I'm here to help with agricultural questions. Could you please provide more specific details about your farming concern?",
            "soil": "For soil-related questions, I recommend testing your soil pH and consulting with local agricultural extension services.",
            "pest": "For pest management, consider integrated pest management (IPM) approaches and consult with local experts for region-specific advice.",
            "crop": "For crop-related questions, factors like local climate, soil conditions, and farming practices are important. Please consult local agricultural experts.",
            "weather": "Weather patterns vary by region. I recommend checking local weather services and agricultural meteorology departments.",
            "fertilizer": "Fertilizer recommendations depend on soil tests and crop requirements. Please consult agricultural extension services for soil testing."
        }
    
    async def check_model_availability(self) -> bool:
        """Check if Ollama model is available"""
        try:
            response = requests.get(f"{self.ollama_url}/api/tags", timeout=5)
            if response.status_code == 200:
                models = response.json().get("models", [])
                model_names = [model["name"] for model in models]
                return self.model_name in model_names
            return False
        except Exception as e:
            logger.warning(f"Cannot connect to Ollama: {e}")
            return False
    
    async def pull_model(self) -> bool:
        """Pull the Ollama model if not available"""
        try:
            logger.info(f"Pulling Ollama model: {self.model_name}")
            
            # Use requests to pull model
            response = requests.post(
                f"{self.ollama_url}/api/pull",
                json={"name": self.model_name},
                stream=True,
                timeout=300  # 5 minutes for model pull
            )
            
            if response.status_code == 200:
                logger.info(f"Successfully pulled model: {self.model_name}")
                return True
            else:
                logger.error(f"Failed to pull model: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"Error pulling model: {e}")
            return False
    
    async def generate_response(
        self,
        question: str,
        context_chunks: List[str],
        language: str = "en"
    ) -> Dict[str, Any]:
        """
        Generate response using Ollama or fallback
        
        Args:
            question: User question
            context_chunks: Retrieved context chunks
            language: Response language
            
        Returns:
            Response dictionary
        """
        start_time = datetime.utcnow()
        
        try:
            # Try Ollama first
            if await self.check_model_availability():
                response = await self._generate_with_ollama(question, context_chunks, language)
                if response:
                    processing_time = (datetime.utcnow() - start_time).total_seconds()
                    return {
                        "answer": response,
                        "confidence": 0.8,
                        "model": self.model_name,
                        "processing_time": processing_time,
                        "timestamp": datetime.utcnow().isoformat()
                    }
            
            # Fallback to rule-based response
            logger.info("Using fallback response generation")
            fallback_response = self._generate_fallback_response(question, context_chunks)
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            return {
                "answer": fallback_response,
                "confidence": 0.6,
                "model": "fallback",
                "processing_time": processing_time,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error in response generation: {e}")
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            return {
                "answer": self.get_fallback_response(question),
                "confidence": 0.2,
                "model": "error_fallback",
                "processing_time": processing_time,
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def _generate_with_ollama(
        self,
        question: str,
        context_chunks: List[str],
        language: str = "en"
    ) -> Optional[str]:
        """Generate response using Ollama API"""
        try:
            prompt = self._build_prompt(question, context_chunks, language)
            
            payload = {
                "model": self.model_name,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "num_predict": self.max_tokens,
                    "temperature": 0.7,
                    "top_p": 0.9
                }
            }
            
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json=payload,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("response", "").strip()
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error calling Ollama: {e}")
            return None
    
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
            # Analyze question to determine category
            question_lower = question.lower()
            
            # Extract relevant information from context
            if context_chunks:
                # Summarize key points from context
                key_points = []
                for chunk in context_chunks[:3]:  # Use top 3 chunks
                    if len(chunk) > 100:
                        # Extract first sentence or key information
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
                    response += "For detailed guidance specific to your region and conditions, please contact local agricultural experts."
                    
                    return response
            
            # Category-specific fallback responses
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
    
    def get_fallback_response(self, question: str) -> str:
        """Get simple fallback response"""
        return "I apologize, but I'm currently unable to provide a detailed response. Please consult with local agricultural experts or extension services for assistance with your farming questions."


# Legacy functions for backward compatibility
def call_ollama(prompt: str, max_tokens: int = 512, stop: list = None) -> str:
    """Legacy function - call ollama via CLI"""
    generator = ResponseGenerator(max_tokens=max_tokens)
    # This is a simplified version for backward compatibility
    try:
        loop = asyncio.get_event_loop()
        result = loop.run_until_complete(
            generator._generate_with_ollama("", [prompt], "en")
        )
        return result or "Error generating response"
    except:
        return "Error generating response"

def build_prompt(query: str, retrieved_texts: list, language: str = "en") -> str:
    """Legacy function - build prompt"""
    generator = ResponseGenerator()
    return generator._build_prompt(query, retrieved_texts, language)

def answer_query(query: str, retrieved_texts: list, language: str = "en") -> str:
    """Legacy function - answer query"""
    generator = ResponseGenerator()
    try:
        loop = asyncio.get_event_loop()
        result = loop.run_until_complete(
            generator.generate_response(query, retrieved_texts, language)
        )
        return result.get("answer", "Error generating response")
    except:
        return generator.get_fallback_response(query)
