# FarmKart AI Services - Quick Setup Guide 🚀

## Prerequisites ✅
- Python 3.8+ installed
- Node.js 16+ installed  
- Flutter app already configured

## 1. Install Python Dependencies (2 minutes)

```bash
# Navigate to AI service directory
cd farmkarts_ai/ai_service

# Install required packages
pip install fastapi uvicorn python-dotenv openai sentence-transformers numpy pandas requests

# Alternative: Install from requirements if available
pip install -r requirements.txt
```

## 2. Install Node.js Dependencies (1 minute)

```bash
# Navigate to proxy service directory
cd ../node_proxy

# Install packages
npm install express axios firebase-admin dotenv cors

# Alternative: Install from package.json
npm install
```

## 3. Start AI Services (30 seconds)

### Option A: Start Both Services Manually

**Terminal 1 - Python AI Service:**
```bash
cd farmkarts_ai/ai_service
python app.py
```
**Should show**: `Server running on http://localhost:8000`

**Terminal 2 - Node Proxy:**
```bash
cd farmkarts_ai/node_proxy  
node aiproxy.js
```
**Should show**: `Server listening on port 3000`

### Option B: Use Batch Script (Windows)
```bash
# From farmkarts_ai directory
./start_services.bat
```

## 4. Verify Services (15 seconds)

### Check Health Status:
```bash
# Test proxy health
curl http://localhost:3000/health

# Expected response:
{
  "status": "healthy", 
  "services": {
    "proxy": {"status": "healthy"},
    "ai_service": {"status": "healthy"}
  }
}
```

## 5. Test Flutter Integration ✅

1. **Launch Flutter App**: `flutter run`
2. **Navigate to AI Chat**: Dashboard → AI Expert (first icon)
3. **Create New Chat**: Tap + button
4. **Ask Question**: "What's the best time to plant wheat?"
5. **Verify Response**: Should get AI-generated farming advice

## Environment Configuration (Optional)

Create `.env` files if you want custom configuration:

### `farmkarts_ai/ai_service/.env`
```env
AI_INTERNAL_KEY=farmkart_ai_secret_key_2024
CORS_ORIGINS=http://localhost,http://127.0.0.1
```

### `farmkarts_ai/node_proxy/.env`  
```env
AI_URL=http://localhost:8000/ask
AI_INTERNAL_KEY=farmkart_ai_secret_key_2024
PORT=3000
```

## Troubleshooting 🔧

### Common Issues:

**1. Port Already in Use (3000)**
```bash
# Kill existing process
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F

# Or use different port in .env
echo "PORT=3001" >> .env
```

**2. Python Module Not Found**
```bash
# Install missing modules
pip install <module_name>

# Or reinstall all
pip install fastapi uvicorn python-dotenv
```

**3. Node Module Not Found**
```bash
# Clear cache and reinstall
npm cache clean --force
npm install
```

**4. AI Service Unreachable**
- Ensure Python service starts on port 8000
- Check firewall settings
- Verify no antivirus blocking

## Default Service URLs 🌐

- **AI Service**: http://localhost:8000
- **Node Proxy**: http://localhost:3000  
- **Health Check**: http://localhost:3000/health
- **AI Endpoint**: http://localhost:3000/ai/advice (requires auth)

## Features Available 🎯

Once running, your app will have:
- ✅ **Instant AI responses** to farming questions
- ✅ **14 specialized categories** (crops, weather, market, etc.)
- ✅ **Chat session management** with history
- ✅ **Quick prompt suggestions** for common questions
- ✅ **Real-time typing indicators** and animations
- ✅ **Confidence scores** and source references
- ✅ **Search and filtering** capabilities

## Production Deployment 🚀

For production, consider:

1. **Use PM2 for Node.js**: `pm2 start aiproxy.js`
2. **Use Gunicorn for Python**: `gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app`
3. **Set up reverse proxy**: Nginx/Apache configuration
4. **Add SSL certificates**: For HTTPS endpoints
5. **Configure monitoring**: Health checks and logging
6. **Set environment variables**: Production API keys and URLs

## Success! 🎉

Your FarmKart AI Expert system is now running and ready to help farmers with intelligent, instant advice on all agricultural topics!

**Test it out**: 
1. Open the Flutter app
2. Tap "AI Expert" on dashboard  
3. Ask: "How do I improve my crop yield?"
4. Watch the magic happen! ✨

---

*Setup complete! Your AI-powered farming assistant is ready to serve users 24/7.*