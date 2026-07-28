@echo off
echo.
echo ========================================
echo   Smart Engineer Backend API
echo ========================================
echo.
cd /d "%~dp0backend_api"
echo Starting server on port 5000...
node server.js
pause
