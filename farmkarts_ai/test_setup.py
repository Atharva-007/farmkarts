#!/usr/bin/env python3
"""
Test setup script for FarmKart AI
Tests basic functionality without heavy dependencies
"""

import os
import sys
import json
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_file_structure():
    """Test that all required files are present"""
    logger.info("Testing file structure...")
    
    required_files = [
        "ai_service/app.py",
        "ai_service/rag_pipeline.py", 
        "ai_service/embeddings.py",
        "ai_service/generator.py",
        "ai_service/index_store.py",
        "ai_service/ingest_api.py",
        "ai_service/requirements.txt",
        "ai_service/corpus.jsonl",
        "node_proxy/aiproxy.js",
        "node_proxy/package.json",
        ".env",
        "docker-compose.yml",
        "README.md"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        logger.error(f"Missing files: {missing_files}")
        return False
    else:
        logger.info("✓ All required files present")
        return True

def test_environment_config():
    """Test environment configuration"""
    logger.info("Testing environment configuration...")
    
    try:
        # Check .env file
        with open('.env', 'r') as f:
            env_content = f.read()
            
        required_vars = [
            'AI_INTERNAL_KEY',
            'OLLAMA_MODEL', 
            'AI_SERVICE_PORT',
            'PORT'
        ]
        
        missing_vars = []
        for var in required_vars:
            if var not in env_content:
                missing_vars.append(var)
        
        if missing_vars:
            logger.error(f"Missing environment variables: {missing_vars}")
            return False
        else:
            logger.info("✓ Environment configuration valid")
            return True
            
    except Exception as e:
        logger.error(f"Error checking environment: {e}")
        return False

def test_corpus_file():
    """Test corpus file format"""
    logger.info("Testing corpus file...")
    
    try:
        docs_count = 0
        with open('ai_service/corpus.jsonl', 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                try:
                    obj = json.loads(line.strip())
                    
                    # Check required fields
                    if 'text' not in obj or not obj['text'].strip():
                        logger.error(f"Line {line_num}: Missing or empty 'text' field")
                        return False
                    
                    if 'source' not in obj:
                        logger.error(f"Line {line_num}: Missing 'source' field")
                        return False
                    
                    docs_count += 1
                    
                except json.JSONDecodeError as e:
                    logger.error(f"Line {line_num}: JSON decode error: {e}")
                    return False
        
        if docs_count == 0:
            logger.error("Corpus file is empty")
            return False
        
        logger.info(f"✓ Corpus file valid with {docs_count} documents")
        return True
        
    except Exception as e:
        logger.error(f"Error checking corpus file: {e}")
        return False

def test_node_dependencies():
    """Test Node.js dependencies"""
    logger.info("Testing Node.js dependencies...")
    
    try:
        # Check if node_modules exists
        if not os.path.exists('node_proxy/node_modules'):
            logger.error("Node modules not installed. Run 'npm install' in node_proxy directory")
            return False
        
        # Check package.json
        with open('node_proxy/package.json', 'r') as f:
            package_data = json.load(f)
        
        required_deps = ['express', 'axios', 'firebase-admin', 'dotenv']
        dependencies = package_data.get('dependencies', {})
        
        missing_deps = []
        for dep in required_deps:
            if dep not in dependencies:
                missing_deps.append(dep)
        
        if missing_deps:
            logger.error(f"Missing Node.js dependencies: {missing_deps}")
            return False
        
        logger.info("✓ Node.js dependencies present")
        return True
        
    except Exception as e:
        logger.error(f"Error checking Node.js dependencies: {e}")
        return False

def test_secrets_directory():
    """Test secrets directory setup"""
    logger.info("Testing secrets directory...")
    
    if not os.path.exists('secrets'):
        logger.error("Secrets directory not found")
        return False
    
    # Check if Firebase credentials exist (optional)
    if os.path.exists('secrets/firebase-admin.json'):
        logger.info("✓ Firebase credentials found")
    else:
        logger.info("⚠ Firebase credentials not found (authentication will be disabled)")
    
    logger.info("✓ Secrets directory present")
    return True

def test_docker_config():
    """Test Docker configuration"""
    logger.info("Testing Docker configuration...")
    
    try:
        with open('docker-compose.yml', 'r') as f:
            compose_content = f.read()
        
        # Check for required services
        required_services = ['ai-service', 'node-proxy']
        missing_services = []
        
        for service in required_services:
            if service not in compose_content:
                missing_services.append(service)
        
        if missing_services:
            logger.error(f"Missing Docker services: {missing_services}")
            return False
        
        logger.info("✓ Docker Compose configuration valid")
        return True
        
    except Exception as e:
        logger.error(f"Error checking Docker config: {e}")
        return False

def test_python_imports():
    """Test basic Python imports (without heavy dependencies)"""
    logger.info("Testing basic Python imports...")
    
    try:
        # Test basic imports
        import json
        import os
        import sys
        import logging
        from datetime import datetime
        from typing import List, Dict, Any, Optional
        
        logger.info("✓ Basic Python imports successful")
        
        # Test if we can import required modules (without ML libraries)
        try:
            import requests
            logger.info("✓ Requests module available")
        except ImportError:
            logger.warning("⚠ Requests module not available")
        
        try:
            import pydantic
            logger.info("✓ Pydantic module available")
        except ImportError:
            logger.warning("⚠ Pydantic module not available")
        
        return True
        
    except Exception as e:
        logger.error(f"Error with basic Python imports: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    logger.info("="*50)
    logger.info("FarmKart AI Setup Test")
    logger.info("="*50)
    
    tests = [
        ("File Structure", test_file_structure),
        ("Environment Config", test_environment_config),
        ("Corpus File", test_corpus_file),
        ("Node Dependencies", test_node_dependencies),
        ("Secrets Directory", test_secrets_directory),
        ("Docker Config", test_docker_config),
        ("Python Imports", test_python_imports)
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        logger.info(f"\n--- {test_name} ---")
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            logger.error(f"Test {test_name} failed with exception: {e}")
            failed += 1
    
    logger.info("\n" + "="*50)
    logger.info("TEST SUMMARY")
    logger.info("="*50)
    logger.info(f"Passed: {passed}")
    logger.info(f"Failed: {failed}")
    logger.info(f"Total:  {passed + failed}")
    
    if failed == 0:
        logger.info("🎉 All tests passed! Setup looks good.")
        logger.info("\nNext steps:")
        logger.info("1. Install Python dependencies: cd ai_service && pip install -r requirements.txt")
        logger.info("2. Place Firebase credentials in secrets/firebase-admin.json (optional)")
        logger.info("3. Start services: start_services.bat or docker-compose up")
        return True
    else:
        logger.info(f"❌ {failed} test(s) failed. Please fix the issues above.")
        return False

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)