@echo off
echo Starting Chrome with disabled security for Flutter web development
echo This allows Flutter web to make requests to localhost backend

start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="C:\temp\chrome_dev_session" --disable-web-security --disable-features=VizDisplayCompositor --disable-site-isolation-trials --allow-running-insecure-content

echo Chrome started with disabled security features
echo You can now run Flutter web app without CORS issues
pause