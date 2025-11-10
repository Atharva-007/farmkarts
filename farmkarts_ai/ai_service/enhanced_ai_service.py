"""
Enhanced AI Service for FarmKart - Focused on Phi3 Optimization
Provides enhanced responses with better prompting and context management
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="FarmKart Enhanced AI Service",
    description="Enhanced Agricultural AI Assistant with optimized Phi3 responses",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
OLLAMA_URL = "http://localhost:11434"
MODEL_NAME = "phi3:latest"
AI_INTERNAL_KEY = "farmkart_internal_2024"

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
    ollama_available: bool
    model_available: bool
    timestamp: str
    version: str

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    ollama_available = await check_ollama_service()
    model_available = await check_model_availability() if ollama_available else False
    
    return HealthResponse(
        status="healthy" if ollama_available and model_available else "degraded",
        ollama_available=ollama_available,
        model_available=model_available,
        timestamp=datetime.utcnow().isoformat(),
        version="2.0.0"
    )

@app.post("/ask", response_model=AskResponse)
async def ask_endpoint(payload: AskRequest, x_api_key: str = Header(None)):
    """Enhanced AI query endpoint with optimized Phi3 responses"""
    
    # Validate API key
    if x_api_key != AI_INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    start_time = time.time()
    
    try:
        # Enhanced query processing
        processed_query = await enhance_query(payload.query, payload.context)
        
        # Try Ollama first with enhanced prompting
        ollama_response = await get_enhanced_ollama_response(
            processed_query, 
            payload.context,
            payload.language
        )
        
        if ollama_response:
            processing_time = time.time() - start_time
            return AskResponse(
                answer=ollama_response["answer"],
                confidence=ollama_response["confidence"],
                sources=ollama_response["sources"],
                model=f"{MODEL_NAME} (Enhanced)",
                retrieval_count=1,
                processing_time=processing_time,
                timestamp=datetime.utcnow().isoformat()
            )
        
        # Fallback to enhanced contextual response
        fallback_response = await get_enhanced_fallback_response(
            payload.query,
            payload.context
        )
        
        processing_time = time.time() - start_time
        return AskResponse(
            answer=fallback_response["answer"],
            confidence=fallback_response["confidence"],
            sources=fallback_response["sources"],
            model="Enhanced Fallback System",
            retrieval_count=0,
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

async def check_ollama_service() -> bool:
    """Check if Ollama service is available"""
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        return response.status_code == 200
    except Exception:
        return False

async def check_model_availability() -> bool:
    """Check if the model is available in Ollama"""
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get("models", [])
            model_names = [model["name"] for model in models]
            return MODEL_NAME in model_names
        return False
    except Exception:
        return False

async def enhance_query(query: str, context: Optional[str] = None) -> str:
    """Enhance the user query with better context and structure"""
    
    # Add farming context if not specified
    if not context:
        context = detect_farming_context(query)
    
    # Enhance query based on context
    enhanced_query = f"[FARMING CONTEXT: {context}] {query}"
    
    return enhanced_query

def detect_farming_context(query: str) -> str:
    """Detect farming context from query"""
    query_lower = query.lower()
    
    if any(word in query_lower for word in ['soil', 'ph', 'fertility', 'nutrients', 'compost']):
        return 'soil_health'
    elif any(word in query_lower for word in ['pest', 'insect', 'disease', 'fungus', 'bug']):
        return 'pest_control'
    elif any(word in query_lower for word in ['water', 'irrigation', 'drought', 'flood']):
        return 'irrigation'
    elif any(word in query_lower for word in ['fertilizer', 'manure', 'organic', 'npk']):
        return 'fertilizers'
    elif any(word in query_lower for word in ['weather', 'climate', 'rain', 'temperature']):
        return 'weather'
    elif any(word in query_lower for word in ['crop', 'seed', 'variety', 'planting', 'harvest']):
        return 'crops'
    elif any(word in query_lower for word in ['price', 'market', 'sell', 'buy', 'profit']):
        return 'market'
    else:
        return 'general'

async def get_enhanced_ollama_response(query: str, context: Optional[str], language: str = "en") -> Optional[Dict[str, Any]]:
    """Get enhanced response from Ollama with optimized prompting"""
    try:
        enhanced_prompt = build_enhanced_prompt(query, context, language)
        
        payload = {
            "model": MODEL_NAME,
            "prompt": enhanced_prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "num_predict": 600,
                "repeat_penalty": 1.1,
                "top_k": 50
            }
        }
        
        response = requests.post(
            f"{OLLAMA_URL}/api/generate",
            json=payload,
            timeout=45
        )
        
        if response.status_code == 200:
            result = response.json()
            raw_response = result.get("response", "").strip()
            
            if raw_response:
                formatted_response = format_enhanced_response(raw_response, context)
                return {
                    "answer": formatted_response,
                    "confidence": 0.85,
                    "sources": ["Phi3 Agricultural Expert", "FarmKart Knowledge Base"]
                }
        
        return None
        
    except Exception as e:
        logger.error(f"Ollama request failed: {e}")
        return None

def build_enhanced_prompt(query: str, context: Optional[str], language: str = "en") -> str:
    """Build enhanced prompt for better Phi3 responses with improved farm context"""
    
    context_info = context or detect_farming_context_advanced(query)
    category_emoji = get_category_emoji(context_info)
    
    # Advanced query analysis
    query_analysis = analyze_farming_query(query)
    
    # Language-specific instructions
    language_instruction = ""
    if language == "hi":
        language_instruction = "कृपया हिंदी में उत्तर दें। "
    elif language != "en":
        language_instruction = f"Please respond in {language}. "
    
    # Season-aware context
    current_season = get_current_indian_season()
    
    prompt = f"""You are Dr. FarmKart AI, India's most advanced agricultural expert system with comprehensive knowledge of Indian farming practices, government schemes, and region-specific solutions.

FARMER PROFILE: {query_analysis['farmer_type']} | SEASON: {current_season}
CONTEXT AREA: {context_info} {category_emoji}
QUERY TYPE: {query_analysis['query_type']} | URGENCY: {query_analysis['urgency']}
FARMER'S QUESTION: {query}

{language_instruction}

Provide a comprehensive, actionable response in this EXACT format:

{category_emoji} **EXPERT ANALYSIS & DIAGNOSIS:**
[Provide detailed 3-4 sentence analysis considering current season, regional factors, and problem urgency]

🎯 **IMMEDIATE ACTION PLAN ({query_analysis['urgency']} Priority):**
1. **{query_analysis['primary_action']}**: [Most critical immediate step with specific details]
2. **Follow-up Action**: [Second important action with timeline]
3. **Monitoring**: [Third step for tracking progress/results]

⚠️ **CRITICAL WARNINGS & PRECAUTIONS:**
• [Primary safety/risk consideration]
• [Secondary precaution specific to season/region]
• [Long-term sustainability warning if applicable]

🌱 **ADVANCED EXPERT RECOMMENDATIONS:**
• **Seasonal Strategy**: [Current season-specific advice]
• **Regional Optimization**: [Location/climate specific tips]
• **Technology Integration**: [Modern tools/apps to enhance results]
• **Quality Enhancement**: [Tips to improve produce quality/yield]

💰 **FINANCIAL ANALYSIS:**
• **Investment Required**: ₹[X,XXX] - ₹[Y,YYY] per acre/hectare
• **Expected ROI**: [X]% increase in [yield/quality/profit] within [timeframe]
• **Cost-Saving Tips**: [Ways to reduce expenses]
• **Government Support**: [Relevant subsidies/schemes with application process]

📊 **SUCCESS METRICS & MONITORING:**
• **Week 1-2**: [What to expect and monitor]
• **Month 1**: [Progress indicators]
• **Season End**: [Final expected outcomes]

🔗 **PROFESSIONAL SUPPORT NETWORK:**
• **Immediate Help**: Contact [local resource] for urgent issues
• **Technical Support**: [Relevant KVK/Extension officer guidance]
• **Market Linkage**: [Where to sell produce at best prices]
• **Certification/Quality**: [Quality standards and certifications to target]

📱 **Digital Tools & Apps:**
[Recommend 2-3 specific apps/tools for ongoing monitoring and management]

---
RESPONSE REQUIREMENTS:
- Provide specific Indian crop varieties, fertilizer brands, and local solutions
- Include exact government scheme names and application procedures  
- Consider regional climate variations (North/South/East/West India)
- Mention seasonal festivals and traditional farming calendars
- Include contact information for local support systems
- Suggest both traditional and modern solutions
- Provide measurable success indicators
- Consider farmer's economic capacity (small/medium/large scale)

Make every recommendation practical, implementable, and economically viable for Indian farmers."""

    return prompt

def detect_farming_context_advanced(query: str) -> str:
    """Advanced farming context detection with regional considerations"""
    query_lower = query.lower()
    
    # Crop-specific contexts
    if any(word in query_lower for word in ['wheat', 'gehun', 'गेहूं']):
        return 'wheat_cultivation'
    elif any(word in query_lower for word in ['rice', 'paddy', 'dhaan', 'धान']):
        return 'rice_cultivation'  
    elif any(word in query_lower for word in ['cotton', 'kapas', 'कपास']):
        return 'cotton_farming'
    elif any(word in query_lower for word in ['sugarcane', 'ganna', 'गन्ना']):
        return 'sugarcane_cultivation'
    elif any(word in query_lower for word in ['vegetable', 'sabzi', 'सब्जी', 'tomato', 'potato']):
        return 'vegetable_farming'
    elif any(word in query_lower for word in ['fruit', 'phal', 'फल', 'mango', 'apple']):
        return 'fruit_cultivation'
    
    # Problem-specific contexts
    elif any(word in query_lower for word in ['soil', 'mitti', 'मिट्टी', 'ph', 'fertility']):
        return 'soil_health'
    elif any(word in query_lower for word in ['pest', 'keet', 'कीट', 'disease', 'rog', 'रोग']):
        return 'pest_disease_management'
    elif any(word in query_lower for word in ['water', 'paani', 'पानी', 'irrigation', 'senchai']):
        return 'water_management'
    elif any(word in query_lower for word in ['fertilizer', 'khad', 'खाद', 'manure']):
        return 'nutrition_management'
    elif any(word in query_lower for word in ['market', 'price', 'bazar', 'बाज़ार', 'sell']):
        return 'market_intelligence'
    elif any(word in query_lower for word in ['weather', 'mausam', 'मौसम', 'climate']):
        return 'climate_agriculture'
    
    return 'general_agriculture'

def analyze_farming_query(query: str) -> dict:
    """Analyze farming query to determine type, urgency, and recommended actions"""
    query_lower = query.lower()
    
    # Determine farmer type
    farmer_type = "General Farmer"
    if any(word in query_lower for word in ['small', 'marginal', 'chota']):
        farmer_type = "Small Scale Farmer"
    elif any(word in query_lower for word in ['large', 'commercial', 'bada']):
        farmer_type = "Commercial Farmer"
    elif any(word in query_lower for word in ['organic', 'natural', 'jaivik']):
        farmer_type = "Organic Farmer"
    
    # Determine urgency
    urgency = "Normal"
    if any(word in query_lower for word in ['urgent', 'emergency', 'dying', 'immediate', 'turant']):
        urgency = "High"
    elif any(word in query_lower for word in ['planning', 'future', 'next season', 'bhavishya']):
        urgency = "Low"
    
    # Determine query type
    query_type = "Information"
    if any(word in query_lower for word in ['how to', 'kaise', 'कैसे', 'method']):
        query_type = "Method/Process"
    elif any(word in query_lower for word in ['problem', 'issue', 'samasya', 'समस्या']):
        query_type = "Problem Solving"
    elif any(word in query_lower for word in ['best', 'recommend', 'suggest', 'sujhav']):
        query_type = "Recommendation"
    elif any(word in query_lower for word in ['cost', 'price', 'kharcha', 'खर्च']):
        query_type = "Economic Analysis"
    
    # Determine primary action category
    primary_action = "Assessment"
    if 'soil' in query_lower:
        primary_action = "Soil Testing"
    elif any(word in query_lower for word in ['pest', 'disease']):
        primary_action = "Field Inspection"
    elif 'water' in query_lower:
        primary_action = "Water Management"
    elif any(word in query_lower for word in ['fertilizer', 'nutrition']):
        primary_action = "Nutrient Analysis"
    
    return {
        'farmer_type': farmer_type,
        'urgency': urgency,
        'query_type': query_type,
        'primary_action': primary_action
    }

def get_current_indian_season() -> str:
    """Get current agricultural season in India"""
    import datetime
    month = datetime.datetime.now().month
    
    if month in [6, 7, 8, 9]:
        return "Kharif Season (Monsoon)"
    elif month in [10, 11, 12, 1, 2, 3]:
        return "Rabi Season (Winter)"
    else:
        return "Zaid Season (Summer)"

def get_category_emoji(context: Optional[str]) -> str:
    """Get appropriate emoji for farming category"""
    if not context:
        return "🚜"
    
    emoji_map = {
        'soil_health': '🌱',
        'pest_control': '🐛',
        'irrigation': '💧',
        'fertilizers': '🌿',
        'weather': '🌤️',
        'crops': '🌾',
        'market': '💰',
        'general': '🚜'
    }
    
    return emoji_map.get(context.lower(), '🚜')

def format_enhanced_response(raw_response: str, context: Optional[str]) -> str:
    """Format and enhance the raw Ollama response"""
    
    # If response already follows our format, return as-is
    if "**EXPERT ANALYSIS:**" in raw_response or "**IMMEDIATE ACTION PLAN:**" in raw_response:
        return raw_response
    
    # Otherwise, enhance the basic response
    category_emoji = get_category_emoji(context)
    context_name = context.replace('_', ' ').title() if context else 'General Farming'
    
    enhanced_response = f"""{category_emoji} **FarmKart Expert Advice - {context_name}**

{raw_response}

---
💡 **Additional Support:**
• For region-specific guidance, consult your local Krishi Vigyan Kendra
• Consider soil testing before implementing fertilizer recommendations  
• Keep detailed records of all farming activities for better decision-making
• Join local Farmer Producer Organizations (FPOs) for group benefits

📱 **FarmKart Services:**
• Quality agricultural inputs and equipment
• Expert consultation and field visits
• Market linkage for better prices
• Latest farming technology and techniques

*This advice is provided by FarmKart's AI agricultural expert system. For complex issues, please consult with local agricultural extension officers.*"""

    return enhanced_response

async def get_enhanced_fallback_response(query: str, context: Optional[str]) -> Dict[str, Any]:
    """Generate enhanced fallback response when Ollama is unavailable"""
    
    query_lower = query.lower()
    context = context or detect_farming_context(query)
    category_emoji = get_category_emoji(context)
    
    # Generate contextual response based on farming category
    if context == 'soil_health':
        answer = f"""{category_emoji} **Soil Health Expert Guidance**

**ANALYSIS:** Your soil health question is crucial for crop productivity and long-term sustainability.

**IMMEDIATE ACTIONS:**
1. **Soil Testing:** Get comprehensive soil testing done at nearest Krishi Vigyan Kendra (₹200-500)
2. **Organic Matter:** Add 10-15 tons well-decomposed FYM or compost per hectare
3. **pH Management:** Adjust pH to 6.0-7.0 using lime (acidic) or gypsum (alkaline)

**IMPORTANT WARNINGS:**
• Never apply fresh/un-decomposed manure directly to crops
• Avoid over-liming which can lock nutrients
• Test soil every 2-3 years for monitoring changes

**EXPERT TIPS:**
• Use vermicompost (2-3 tons/ha) for quick soil improvement
• Practice crop rotation with legumes to fix nitrogen naturally  
• Green manuring with dhaincha/sunhemp adds 150-200 kg N/ha

**COST & TIMELINE:**
• Investment: ₹5,000-15,000 per hectare for complete soil improvement
• Visible results: 1-2 growing seasons
• Long-term benefits: 20-30% increase in productivity

**SUPPORT:** Contact local agricultural extension officer for soil health card and government subsidies."""

    elif context == 'pest_control':
        answer = f"""{category_emoji} **Integrated Pest Management Expert**

**ANALYSIS:** Effective pest control requires a systematic approach combining prevention, monitoring, and targeted intervention.

**IMMEDIATE ACTIONS:**
1. **Field Scouting:** Inspect crops 2-3 times weekly during critical growth stages
2. **IPM Approach:** Start with biological control, use chemicals only when necessary
3. **Threshold Monitoring:** Apply treatments only when pest population exceeds economic threshold

**IMPORTANT WARNINGS:**
• Always read pesticide labels and follow dosage instructions
• Use protective equipment during pesticide application
• Maintain pre-harvest interval strictly before harvesting

**EXPERT TIPS:**
• Install pheromone traps for early detection and monitoring
• Encourage beneficial insects with border crops and refugia
• Use neem-based products (0.5%) for organic pest control

**COST & TIMELINE:**
• IPM setup cost: ₹2,000-5,000 per hectare
• Pesticide cost reduction: 30-50% compared to calendar spraying
• Effectiveness: 85-90% pest control with proper implementation

**SUPPORT:** Connect with nearest Plant Protection Office for pest identification and management advice."""

    elif context == 'irrigation':
        answer = f"""{category_emoji} **Water Management Expert System**

**ANALYSIS:** Efficient water management is critical for crop productivity and sustainability, especially in variable rainfall conditions.

**IMMEDIATE ACTIONS:**
1. **System Upgrade:** Install drip/sprinkler irrigation for 30-50% water savings
2. **Scheduling:** Irrigate based on soil moisture, not calendar (early morning/evening)
3. **Conservation:** Use mulching to reduce evaporation by 40-60%

**IMPORTANT WARNINGS:**
• Avoid waterlogging which causes root rot and nutrient loss
• Don't irrigate during peak sun hours (10 AM - 4 PM)
• Test water quality regularly for salinity and pH

**EXPERT TIPS:**  
• Use tensiometers or soil auger to check moisture at root zone
• Collect rainwater in farm ponds for supplemental irrigation
• Practice alternate wetting and drying (AWD) in rice to save 15-20% water

**COST & TIMELINE:**
• Drip system: ₹40,000-80,000 per hectare (50-90% govt subsidy available)
• Water savings: 30-50% with improved efficiency
• Payback period: 2-3 years through water savings and higher yields

**SUPPORT:** Apply for Pradhan Mantri Krishi Sinchayee Yojana (PMKSY) subsidies through local agriculture department."""

    else:
        # General farming advice
        answer = f"""{category_emoji} **FarmKart Agricultural Expert**

**ANALYSIS:** Your farming question requires a comprehensive approach considering multiple factors like soil, climate, and local conditions.

**IMMEDIATE ACTIONS:**
1. **Assessment:** Evaluate your current farming practices and identify improvement areas
2. **Planning:** Develop a season-wise crop plan based on market demand and resources
3. **Quality Inputs:** Use certified seeds, appropriate fertilizers, and approved plant protection

**IMPORTANT WARNINGS:**
• Always follow recommended dosages for fertilizers and pesticides
• Maintain proper record-keeping for all farming activities
• Consider weather forecasts before major farming operations

**EXPERT TIPS:**
• Adopt integrated farming systems for risk distribution and steady income
• Join Farmer Producer Organizations (FPOs) for better input prices and market access
• Use technology tools like mobile apps for weather, market prices, and expert advice

**COST & TIMELINE:**
• Modern farming adoption: ₹20,000-50,000 per hectare initial investment
• Expected improvement: 20-40% increase in productivity
• Break-even period: 1-2 crop seasons with proper management

**SUPPORT:** Contact local Krishi Vigyan Kendra, agricultural extension officer, or FarmKart experts for personalized guidance."""

    return {
        "answer": answer,
        "confidence": 0.75,
        "sources": ["FarmKart Expert Knowledge Base", "Agricultural Best Practices Database", "Indian Farming Guidelines"]
    }

@app.get("/stats")
async def get_stats():
    """Get service statistics"""
    ollama_available = await check_ollama_service()
    model_available = await check_model_availability() if ollama_available else False
    
    return {
        "service_status": "healthy" if ollama_available else "degraded",
        "ollama_available": ollama_available,
        "model_available": model_available,
        "model_name": MODEL_NAME,
        "features": [
            "Enhanced Phi3 prompting",
            "Context-aware responses", 
            "Indian farming expertise",
            "Multi-language support",
            "Structured response format"
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    print("="*50)
    print("FarmKart Enhanced AI Service")
    print("="*50)
    print("Starting enhanced AI service with optimized Phi3...")
    print(f"Ollama URL: {OLLAMA_URL}")
    print(f"Model: {MODEL_NAME}")
    print("Features: Enhanced prompting, structured responses, Indian farming expertise")
    print("="*50)
    
    uvicorn.run(app, host="0.0.0.0", port=8000)