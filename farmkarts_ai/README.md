# FarmKart AI Service

A comprehensive AI-powered agricultural expert system using RAG (Retrieval Augmented Generation) architecture. This service provides intelligent farming advice through a combination of local knowledge base and AI language models.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│   Node Proxy    │────│   AI Service    │
│   (Frontend)    │    │   (Auth Layer)  │    │   (FastAPI)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                              ┌─────────────────────────┼─────────────────────────┐
                              │                         │                         │
                       ┌──────▼──────┐        ┌────────▼────────┐      ┌────────▼────────┐
                       │  Embedding  │        │  Vector Index   │      │   AI Generator  │
                       │  Service    │        │    (FAISS)      │      │   (Ollama/LLM)  │
                       │ (SentenceTr)│        │                 │      │                 │
                       └─────────────┘        └─────────────────┘      └─────────────────┘
```

## 🚀 Features

- **RAG Pipeline**: Retrieval Augmented Generation for accurate agricultural advice
- **Multi-language Support**: English and Hindi language support
- **Firebase Authentication**: Secure user authentication and authorization
- **Vector Search**: FAISS-powered semantic search through agricultural knowledge
- **Ollama Integration**: Local AI model for response generation with fallback support
- **Document Ingestion**: PDF and text document processing for knowledge base expansion
- **Health Monitoring**: Comprehensive health checks and monitoring endpoints
- **Docker Support**: Full containerization with Docker Compose

## 📋 Prerequisites

- **Python 3.8+** with pip
- **Node.js 16+** with npm
- **Docker & Docker Compose** (optional, for containerized deployment)
- **Ollama** (optional, for local AI model hosting)

## 🛠️ Quick Setup

### Option 1: Automated Setup (Windows)

1. **Clone and navigate to the project**:
   ```bash
   cd farmkarts_new/farmkarts_ai
   ```

2. **Run the setup script**:
   ```bash
   setup.bat
   ```

3. **Configure Firebase** (optional but recommended):
   - Place your Firebase service account JSON file in `secrets/firebase-admin.json`
   - If skipped, authentication will be disabled

4. **Start the services**:
   ```bash
   start_services.bat
   ```

### Option 2: Manual Setup

1. **Set up Python environment**:
   ```bash
   cd ai_service
   pip install -r requirements.txt
   cd ..
   ```

2. **Set up Node.js environment**:
   ```bash
   cd node_proxy
   npm install
   cd ..
   ```

3. **Configure environment**:
   ```bash
   cp docs/.env.example .env
   # Edit .env with your configuration
   ```

4. **Build knowledge base**:
   ```bash
   python build_index.py
   ```

5. **Start services**:
   ```bash
   # Terminal 1: AI Service
   cd ai_service
   python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload

   # Terminal 2: Node Proxy
   cd node_proxy
   node aiproxy.js
   ```

### Option 3: Docker Deployment

1. **Set up environment**:
   ```bash
   cp docs/.env.example .env
   # Edit .env with your configuration
   ```

2. **Create secrets directory**:
   ```bash
   mkdir secrets
   # Place firebase-admin.json in secrets/ directory
   ```

3. **Deploy with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

## 🔧 Configuration

### Environment Variables (.env)

```env
# API Security
AI_INTERNAL_KEY=your_secure_api_key_here

# AI Model Configuration
OLLAMA_MODEL=llama3.2:1b
AI_SERVICE_HOST=localhost
AI_SERVICE_PORT=8000

# Node Proxy Configuration
PORT=3000
AI_URL=http://localhost:8000/ask

# Firebase Configuration
FIREBASE_CRED_PATH=./secrets/firebase-admin.json

# RAG Configuration
SIMILARITY_THRESHOLD=0.3
MAX_CONTEXT_CHUNKS=5
EMBEDDING_MODEL=all-MiniLM-L6-v2
```

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Generate a service account key (JSON file)
3. Place the JSON file in `secrets/firebase-admin.json`
4. Update the path in your `.env` file

## 📚 API Documentation

### Authentication

All API endpoints (except health checks) require Firebase authentication:

```bash
Authorization: Bearer <firebase_id_token>
```

### Main Endpoints

#### 1. Get AI Advice
```http
POST /ai/advice
Content-Type: application/json
Authorization: Bearer <token>

{
  "query": "How to treat tomato blight?",
  "language": "en",
  "context": "I have a 2-acre tomato farm in Maharashtra"
}
```

**Response:**
```json
{
  "answer": "For tomato blight treatment...",
  "confidence": 0.85,
  "sources": [...],
  "model": "llama3.2:1b",
  "retrieval_count": 3,
  "processing_time": 1.24,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 2. Bulk Advice (up to 10 queries)
```http
POST /ai/advice/bulk
Content-Type: application/json
Authorization: Bearer <token>

{
  "queries": [
    "Best fertilizer for wheat?",
    "How to control aphids?",
    "When to harvest rice?"
  ],
  "language": "en"
}
```

#### 3. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "proxy": {"status": "healthy"},
    "ai_service": {"status": "healthy", "pipeline_initialized": true},
    "firebase": {"status": "initialized"}
  }
}
```

#### 4. Service Statistics (Admin only)
```http
GET /ai/stats
Authorization: Bearer <admin_token>
```

### Admin Endpoints (AI Service)

#### 1. Ingest Documents
```http
POST /admin/ingest
Content-Type: application/json
x-api-key: your_ai_internal_key

{
  "chunks": [
    {
      "text": "Tomato cultivation requires...",
      "source": "agricultural_handbook",
      "title": "Tomato Growing Guide",
      "category": "vegetables",
      "language": "en"
    }
  ]
}
```

#### 2. Upload PDF
```http
POST /admin/ingest/pdf
Content-Type: multipart/form-data
x-api-key: your_ai_internal_key

file: [PDF file]
document_info: {"title": "Farming Guide", "source": "extension_office"}
```

#### 3. Search Knowledge Base
```http
POST /admin/search
Content-Type: application/json
x-api-key: your_ai_internal_key

{
  "query": "pest management",
  "k": 5,
  "threshold": 0.3
}
```

## 📊 Monitoring & Health Checks

### Service URLs

- **AI Service**: http://localhost:8000
- **Node Proxy**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **AI Service Docs**: http://localhost:8000/docs (FastAPI auto-docs)

### Health Check Response

The health check endpoint provides comprehensive status information:

```json
{
  "status": "healthy|degraded|unhealthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "proxy": {
      "status": "healthy",
      "port": 3000
    },
    "ai_service": {
      "status": "healthy",
      "pipeline_initialized": true,
      "url": "http://localhost:8000/ask"
    },
    "firebase": {
      "status": "initialized|disabled",
      "authentication_enabled": true
    }
  }
}
```

## 🧠 Knowledge Base Management

### Adding Content

1. **Via API** (recommended for applications):
   ```bash
   curl -X POST "http://localhost:8000/admin/ingest" \
     -H "x-api-key: your_key" \
     -H "Content-Type: application/json" \
     -d '{"chunks": [{"text": "Your content...", "source": "source_name"}]}'
   ```

2. **Via PDF Upload**:
   ```bash
   curl -X POST "http://localhost:8000/admin/ingest/pdf" \
     -H "x-api-key: your_key" \
     -F "file=@agricultural_guide.pdf" \
     -F "document_info={\"title\": \"Agricultural Guide\"}"
   ```

3. **Via Corpus File**:
   - Add entries to `ai_service/corpus.jsonl`
   - Run: `python build_index.py`

### Corpus File Format

```jsonl
{"text": "Content about soil management...", "source": "soil_guide", "category": "soil", "language": "en"}
{"text": "Information about pest control...", "source": "pest_manual", "category": "pests", "language": "en"}
```

## 🐛 Troubleshooting

### Common Issues

1. **"Pipeline not initialized" error**:
   - Check if corpus.jsonl exists and has content
   - Run `python build_index.py` to rebuild the index
   - Check AI service logs for initialization errors

2. **"AI service unavailable" error**:
   - Verify AI service is running on port 8000
   - Check if Ollama is running (if using local models)
   - Verify AI_INTERNAL_KEY matches between services

3. **Authentication failures**:
   - Verify Firebase credentials are correctly placed
   - Check if the service account has proper permissions
   - Ensure the Firebase project is properly configured

4. **Empty responses**:
   - Check if the knowledge base has content
   - Verify similarity threshold isn't too high
   - Review query preprocessing and embedding generation

### Logs

- **AI Service logs**: Check console output or Docker logs
- **Node Proxy logs**: Check console output or Docker logs
- **Health status**: Visit http://localhost:3000/health

### Performance Tuning

1. **Adjust similarity threshold** in .env (0.1-0.7 range)
2. **Increase context chunks** for more comprehensive answers
3. **Use GPU acceleration** for faster embedding generation
4. **Optimize Ollama model size** based on available resources

## 🔄 Development

### Project Structure

```
farmkarts_ai/
├── ai_service/           # Python FastAPI service
│   ├── app.py           # Main application
│   ├── rag_pipeline.py  # RAG orchestration
│   ├── embeddings.py    # Embedding service
│   ├── generator.py     # Response generation
│   ├── index_store.py   # Vector index management
│   ├── ingest_api.py    # Document ingestion API
│   └── corpus.jsonl     # Sample knowledge base
├── node_proxy/          # Node.js authentication proxy
│   ├── aiproxy.js       # Main proxy service
│   └── package.json     # Dependencies
├── secrets/             # Firebase credentials
├── docs/                # Documentation and examples
├── .env                 # Environment configuration
├── docker-compose.yml   # Docker orchestration
├── setup.bat           # Windows setup script
└── start_services.bat  # Windows startup script
```

### Adding New Features

1. **New endpoints**: Add to `ai_service/app.py` or `node_proxy/aiproxy.js`
2. **RAG improvements**: Modify `ai_service/rag_pipeline.py`
3. **New data sources**: Extend `ai_service/ingest_api.py`
4. **Authentication logic**: Update `node_proxy/aiproxy.js`

### Testing

```bash
# Test AI service directly
curl -X POST "http://localhost:8000/ask" \
  -H "x-api-key: your_key" \
  -H "Content-Type: application/json" \
  -d '{"query": "test query"}'

# Test through proxy (requires auth token)
curl -X POST "http://localhost:3000/ai/advice" \
  -H "Authorization: Bearer your_firebase_token" \
  -H "Content-Type: application/json" \
  -d '{"query": "test query"}'
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is part of the FarmKart ecosystem. Please refer to the main project license.

## 🆘 Support

For support and questions:
1. Check the troubleshooting section above
2. Review health check endpoint output
3. Check service logs for detailed error messages
4. Create an issue in the project repository

---

**Happy Farming! 🌾**