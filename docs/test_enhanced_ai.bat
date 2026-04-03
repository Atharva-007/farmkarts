@echo off
echo ===============================================
echo Testing Enhanced FarmKart AI Services
echo ===============================================

echo.
echo 1. Testing Health Endpoint...
curl -X GET "http://localhost:3000/health" -H "Content-Type: application/json"

echo.
echo.
echo 2. Testing Enhanced AI Endpoint with Sample Farming Query...
curl -X POST "http://localhost:3000/ask" ^
-H "Content-Type: application/json" ^
-H "X-API-Key: farmkart_internal_2024" ^
-d "{\"query\": \"How can I improve soil fertility for wheat cultivation?\", \"context\": \"soil_health\", \"user_id\": \"test_user\"}"

echo.
echo.
echo 3. Testing Pest Control Query...
curl -X POST "http://localhost:3000/ask" ^
-H "Content-Type: application/json" ^
-H "X-API-Key: farmkart_internal_2024" ^
-d "{\"query\": \"What are the best methods for controlling aphids in my vegetable crops?\", \"context\": \"pest_control\", \"user_id\": \"test_user\"}"

echo.
echo.
echo 4. Testing Direct RAG Service (if available)...
curl -X POST "http://localhost:8000/ask" ^
-H "Content-Type: application/json" ^
-H "x-api-key: farmkart_internal_2024" ^
-d "{\"query\": \"Best irrigation methods for rice cultivation in India\", \"context\": \"irrigation\", \"user_id\": \"test_user\", \"language\": \"en\"}"

echo.
echo.
echo ===============================================
echo Test Complete!
echo.
echo If you see JSON responses above, the enhanced AI system is working correctly.
echo If you see error messages, check that all services are running properly.
echo.
echo Run start_enhanced_ai.bat if services are not started.
echo ===============================================
pause