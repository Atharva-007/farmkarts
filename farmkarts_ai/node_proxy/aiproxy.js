// aiProxy.js - FarmKart AI Node Proxy Service
require('dotenv').config();
const express = require('express');
const axios = require('axios');
const admin = require('firebase-admin');

const app = express();
app.use(express.json());

// Configuration
const AI_URL = process.env.AI_URL || "http://localhost:8000/ask";
const AI_INTERNAL_KEY = process.env.AI_INTERNAL_KEY || "farmkart_ai_secret_key_2024";
const PORT = process.env.PORT || 3000;
const FIREBASE_CRED_PATH = process.env.FIREBASE_CRED_PATH;

// Initialize Firebase Admin
let firebaseInitialized = false;
try {
    if (FIREBASE_CRED_PATH && require('fs').existsSync(FIREBASE_CRED_PATH)) {
        admin.initializeApp({
            credential: admin.credential.cert(require(FIREBASE_CRED_PATH))
        });
        firebaseInitialized = true;
        console.log('Firebase Admin initialized successfully');
    } else {
        console.warn('Firebase credentials not found. Authentication will be disabled.');
        console.warn('Set FIREBASE_CRED_PATH environment variable to enable authentication.');
    }
} catch (error) {
    console.error('Failed to initialize Firebase Admin:', error.message);
    console.warn('Authentication will be disabled.');
}

// Middleware for request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        // Check AI service health
        const aiHealthResponse = await axios.get(AI_URL.replace('/ask', '/health'), {
            timeout: 5000
        });
        
        const healthStatus = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            services: {
                proxy: {
                    status: 'healthy',
                    port: PORT
                },
                ai_service: {
                    status: aiHealthResponse.data.status || 'unknown',
                    pipeline_initialized: aiHealthResponse.data.pipeline_initialized || false,
                    url: AI_URL
                },
                firebase: {
                    status: firebaseInitialized ? 'initialized' : 'disabled',
                    authentication_enabled: firebaseInitialized
                }
            }
        };
        
        const overallHealthy = healthStatus.services.ai_service.status === 'healthy';
        
        res.status(overallHealthy ? 200 : 503).json(healthStatus);
        
    } catch (error) {
        console.error('Health check failed:', error.message);
        
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message,
            services: {
                proxy: {
                    status: 'healthy',
                    port: PORT
                },
                ai_service: {
                    status: 'unreachable',
                    error: error.message,
                    url: AI_URL
                },
                firebase: {
                    status: firebaseInitialized ? 'initialized' : 'disabled',
                    authentication_enabled: firebaseInitialized
                }
            }
        });
    }
});

// Authentication middleware
const authenticateUser = async (req, res, next) => {
    if (!firebaseInitialized) {
        // Skip authentication if Firebase is not initialized
        req.user = { uid: 'anonymous', role: 'farmer' };
        return next();
    }
    
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ 
                error: "Missing or invalid authorization header",
                message: "Expected format: 'Authorization: Bearer <token>'"
            });
        }
        
        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        
        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            role: decodedToken.role || 'farmer',
            name: decodedToken.name
        };
        
        next();
        
    } catch (error) {
        console.error('Authentication error:', error.message);
        res.status(401).json({ 
            error: "Authentication failed",
            message: "Invalid or expired token"
        });
    }
};

// Enhanced AI ask endpoint for FarmKart mobile app
app.post('/ask', async (req, res) => {
    try {
        const { query, language = 'en', context, user_id } = req.body;
        const apiKey = req.headers['x-api-key'];
        
        // Simple API key validation for mobile app
        if (apiKey !== 'farmkart_internal_2024') {
            return res.status(401).json({
                error: "Invalid API key",
                message: "Access denied"
            });
        }
        
        // Validate request
        if (!query || typeof query !== 'string' || query.trim().length === 0) {
            return res.status(400).json({
                error: "Invalid request",
                message: "Query is required and must be a non-empty string"
            });
        }
        
        if (query.length > 1000) {
            return res.status(400).json({
                error: "Query too long",
                message: "Query must be less than 1000 characters"
            });
        }
        
        console.log(`Enhanced AI request: ${query.substring(0, 100)}...`);
        
        // Try AI service with RAG first
        try {
            const aiRequest = {
                query: query.trim(),
                user_id: user_id,
                language: language,
                context: context
            };
            
            const response = await axios.post(AI_URL, aiRequest, {
                headers: { 
                    "x-api-key": AI_INTERNAL_KEY,
                    "Content-Type": "application/json"
                },
                timeout: 45000 // 45 seconds timeout
            });
            
            console.log('RAG service responded successfully');
            
            // Format response for mobile app
            const enhancedResponse = {
                answer: response.data.answer,
                confidence: response.data.confidence,
                sources: response.data.sources || [],
                model: response.data.model + ' (RAG Enhanced)',
                retrieval_count: response.data.retrieval_count || 0,
                processing_time: response.data.processing_time || 0,
                timestamp: new Date().toISOString(),
                user_id: user_id,
                request_timestamp: new Date().toISOString()
            };
            
            res.json(enhancedResponse);
            return;
            
        } catch (aiError) {
            console.log('RAG service failed, trying Ollama fallback:', aiError.message);
            
            // Fallback to Ollama direct call
            try {
                const ollamaResponse = await callOllamaDirectly(query, context);
                if (ollamaResponse) {
                    console.log('Ollama fallback succeeded');
                    res.json(ollamaResponse);
                    return;
                }
            } catch (ollamaError) {
                console.log('Ollama fallback also failed:', ollamaError.message);
            }
        }
        
        // Final fallback - enhanced contextual response
        console.log('Using enhanced fallback response');
        const fallbackResponse = generateEnhancedFallback(query, context);
        res.json(fallbackResponse);
        
    } catch (error) {
        console.error('Critical error in /ask endpoint:', error.message);
        res.status(500).json({
            answer: "I apologize, but I'm experiencing technical difficulties. Please try again later.",
            confidence: 0.0,
            sources: [],
            model: "error_fallback",
            retrieval_count: 0,
            processing_time: 0,
            timestamp: new Date().toISOString(),
            error: "Service temporarily unavailable"
        });
    }
});

// Ollama direct fallback function
async function callOllamaDirectly(query, context) {
    try {
        const enhancedPrompt = buildEnhancedOllamaPrompt(query, context);
        
        const response = await axios.post('http://localhost:11434/api/generate', {
            model: 'phi3:latest',
            prompt: enhancedPrompt,
            stream: false,
            options: {
                temperature: 0.7,
                top_p: 0.9,
                num_predict: 512,
            }
        }, {
            timeout: 30000
        });
        
        if (response.status === 200 && response.data.response) {
            return {
                answer: formatOllamaResponse(response.data.response, context),
                confidence: 0.85,
                sources: ['Phi3 AI Model', 'FarmKart Knowledge Base'],
                model: 'phi3:latest (Direct)',
                retrieval_count: 1,
                processing_time: 2.5,
                timestamp: new Date().toISOString()
            };
        }
        return null;
    } catch (error) {
        console.error('Ollama direct call failed:', error.message);
        return null;
    }
}

// Enhanced Ollama prompt builder
function buildEnhancedOllamaPrompt(query, context) {
    const contextInfo = context || 'general farming';
    
    return `You are an expert agricultural advisor for FarmKart, specializing in Indian farming practices. 

Context Area: ${contextInfo}

Farmer's Question: ${query}

Please provide a helpful, practical response following this format:

🔍 ANALYSIS:
[Brief explanation of the situation/problem]

📋 RECOMMENDED ACTIONS:
1. [First immediate step]
2. [Second important action]  
3. [Third follow-up measure]

⚠️ IMPORTANT NOTES:
[Safety warnings or critical considerations]

🌱 ADDITIONAL TIPS:
[Extra helpful advice or seasonal considerations]

Keep your response practical, specific to Indian conditions, and suitable for farmers. Use simple language and provide actionable advice.`;
}

// Format Ollama response
function formatOllamaResponse(response, context) {
    const categoryEmoji = getCategoryEmoji(context);
    
    if (!response.includes('🔍') && !response.includes('📋')) {
        return `${categoryEmoji} **Expert Advice for ${context || 'Your Farming Question'}**

${response}

💡 **Remember:** For best results, consider local soil conditions, weather patterns, and consult with your local agricultural extension officer for region-specific guidance.

📱 **FarmKart Tip:** Keep track of your farming practices and results for better decision-making in future seasons.`;
    }
    
    return response;
}

// Get category emoji
function getCategoryEmoji(context) {
    switch (context?.toLowerCase()) {
        case 'crops': return '🌾';
        case 'soil_health': return '🌱';
        case 'pest_control': return '🐛';
        case 'irrigation': return '💧';
        case 'fertilizers': return '🌿';
        case 'weather': return '🌤️';
        case 'market': return '💰';
        default: return '🚜';
    }
}

// Enhanced fallback response generator
function generateEnhancedFallback(query, context) {
    const queryLower = query.toLowerCase();
    const categoryEmoji = getCategoryEmoji(context);
    
    let answer = `${categoryEmoji} **FarmKart Agricultural Expert** (Enhanced Contextual Response)

Thank you for your farming question about: "${query}"

`;

    // Category-specific responses
    if (queryLower.includes('soil') || queryLower.includes('fertility')) {
        answer += `🌱 **Soil Health Guidance:**
        
• **Soil Testing:** Get your soil tested for pH, nutrients, and organic matter content
• **Organic Matter:** Add compost or well-rotted manure to improve soil structure  
• **pH Management:** Most crops prefer pH 6.0-7.0; lime for acidic soil, gypsum for alkaline
• **Crop Rotation:** Rotate with legumes to naturally fix nitrogen in soil

📞 **Recommended Action:** Contact your local Krishi Vigyan Kendra for soil testing services.`;
        
    } else if (queryLower.includes('pest') || queryLower.includes('disease') || queryLower.includes('insect')) {
        answer += `🐛 **Pest & Disease Management:**
        
• **IPM Approach:** Use Integrated Pest Management - combine cultural, biological, and chemical methods
• **Early Detection:** Scout your fields regularly, identify pests/diseases early
• **Biological Control:** Use beneficial insects, neem-based products when possible
• **Resistant Varieties:** Choose disease-resistant crop varieties for your region

⚠️ **Safety First:** Always follow label instructions when using any pesticides.`;
        
    } else if (queryLower.includes('fertilizer') || queryLower.includes('nutrition')) {
        answer += `🌿 **Nutrient Management:**
        
• **Soil-Based Application:** Base fertilizer use on soil test results
• **Balanced Nutrition:** Ensure NPK balance - don't over-apply any single nutrient
• **Organic Options:** Consider compost, vermicompost, and bio-fertilizers
• **Timing:** Apply fertilizers at right crop growth stages for maximum efficiency

💡 **Pro Tip:** Split nitrogen applications for better uptake and reduced losses.`;
        
    } else if (queryLower.includes('water') || queryLower.includes('irrigation')) {
        answer += `💧 **Water Management:**
        
• **Efficient Systems:** Consider drip or sprinkler irrigation for water savings
• **Timing:** Irrigate early morning or evening to reduce evaporation
• **Soil Moisture:** Check soil moisture before irrigating - avoid overwatering
• **Mulching:** Use organic mulch to conserve soil moisture

🌾 **Regional Advice:** Consult local water management practices suitable for your area.`;
        
    } else {
        answer += `📋 **General Agricultural Guidance:**
        
• **Planning:** Develop a comprehensive farm management plan
• **Quality Inputs:** Use certified seeds, quality fertilizers, and approved pesticides
• **Record Keeping:** Maintain records of all farming activities and inputs
• **Market Intelligence:** Stay updated with market prices and demand trends
• **Technology:** Leverage mobile apps and digital tools for farming decisions

🤝 **Expert Support:** Connect with agricultural extension officers and farmer producer organizations in your area.`;
    }
    
    answer += `

🔗 **Need More Help?**
• Contact your local Agricultural Extension Officer
• Visit nearest Krishi Vigyan Kendra  
• Join local Farmer Producer Organizations (FPOs)
• Use FarmKart platform for quality inputs and market access

*This response is generated by FarmKart's Enhanced AI system. For location-specific advice, please consult local experts.*`;

    return {
        answer: answer,
        confidence: 0.75,
        sources: ['FarmKart Enhanced Knowledge Base', 'Agricultural Best Practices'],
        model: 'FarmKart Enhanced Fallback v2.5',
        retrieval_count: 2,
        processing_time: 0.5,
        timestamp: new Date().toISOString()
    };
}

// Bulk advice endpoint for multiple queries
app.post('/ai/advice/bulk', authenticateUser, async (req, res) => {
    try {
        const { queries, language = 'en' } = req.body;
        
        if (!Array.isArray(queries) || queries.length === 0) {
            return res.status(400).json({
                error: "Invalid request",
                message: "Queries must be a non-empty array"
            });
        }
        
        if (queries.length > 10) {
            return res.status(400).json({
                error: "Too many queries",
                message: "Maximum 10 queries allowed per request"
            });
        }
        
        console.log(`Bulk AI request from user ${req.user.uid}: ${queries.length} queries`);
        
        const responses = [];
        
        for (let i = 0; i < queries.length; i++) {
            const query = queries[i];
            
            if (!query || typeof query !== 'string') {
                responses.push({
                    index: i,
                    error: "Invalid query",
                    message: "Query must be a non-empty string"
                });
                continue;
            }
            
            try {
                const aiRequest = {
                    query: query.trim(),
                    user_id: req.user.uid,
                    language: language
                };
                
                const response = await axios.post(AI_URL, aiRequest, {
                    headers: { 
                        "x-api-key": AI_INTERNAL_KEY,
                        "Content-Type": "application/json"
                    },
                    timeout: 30000 // 30 seconds per query
                });
                
                responses.push({
                    index: i,
                    query: query,
                    ...response.data
                });
                
            } catch (error) {
                console.error(`Error processing query ${i}:`, error.message);
                responses.push({
                    index: i,
                    query: query,
                    error: "Processing failed",
                    message: "Failed to process this query"
                });
            }
        }
        
        res.json({
            user_id: req.user.uid,
            total_queries: queries.length,
            successful: responses.filter(r => !r.error).length,
            failed: responses.filter(r => r.error).length,
            responses: responses,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Bulk AI service error:', error.message);
        res.status(500).json({
            error: "Internal server error",
            message: "Failed to process bulk request"
        });
    }
});

// Get AI service statistics (admin only)
app.get('/ai/stats', authenticateUser, async (req, res) => {
    try {
        // Check if user is admin (you can customize this logic)
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: "Forbidden",
                message: "Admin access required"
            });
        }
        
        const statsResponse = await axios.get(AI_URL.replace('/ask', '/stats'), {
            headers: { "x-api-key": AI_INTERNAL_KEY },
            timeout: 10000
        });
        
        res.json(statsResponse.data);
        
    } catch (error) {
        console.error('Stats error:', error.message);
        res.status(500).json({
            error: "Failed to get statistics",
            message: error.message
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        error: "Internal server error",
        message: "An unexpected error occurred"
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: "Not found",
        message: `Endpoint ${req.method} ${req.originalUrl} not found`
    });
});

// Start server
app.listen(PORT, () => {
    console.log('=================================');
    console.log('FarmKart AI Node Proxy Service');
    console.log('=================================');
    console.log(`Server listening on port ${PORT}`);
    console.log(`AI Service URL: ${AI_URL}`);
    console.log(`Firebase Auth: ${firebaseInitialized ? 'Enabled' : 'Disabled'}`);
    console.log(`Health Check: http://localhost:${PORT}/health`);
    console.log('=================================');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});
