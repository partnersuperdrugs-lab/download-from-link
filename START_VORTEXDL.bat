@echo off
setlocal EnableDelayedExpansion
title VortexDL — Video Downloader Launcher
color 0A

:: ============================================================
::  VortexDL — One-click launcher
::  Checks Python, installs deps, starts server, opens browser
:: ============================================================

echo.
echo  ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗██████╗ ██╗
echo  ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝██╔══██╗██║
echo  ██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝ ██║  ██║██║
echo  ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ ██║  ██║██║
echo   ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗██████╔╝███████╗
echo    ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
echo.
echo  [ TikTok No-WM ^| Instagram HD ^| YT Shorts ^| 1000+ Sites ]
echo  ============================================================
echo.

:: ── STEP 1: Check Python ─────────────────────────────────────────────
echo  [1/5] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Python is not installed or not in PATH.
    echo.
    echo  Please install Python 3.8+ from:
    echo  https://www.python.org/downloads/
    echo.
    echo  IMPORTANT: During install, check "Add Python to PATH"
    echo.
    pause
    start https://www.python.org/downloads/
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo  [OK] Found: %PYVER%

:: ── STEP 2: Check pip ────────────────────────────────────────────────
echo.
echo  [2/5] Checking pip...
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  [INFO] pip not found. Installing pip...
    python -m ensurepip --upgrade
)
echo  [OK] pip ready.

:: ── STEP 3: Install / upgrade dependencies ───────────────────────────
echo.
echo  [3/5] Installing / checking dependencies...
echo        (flask, yt-dlp, flask-cors)
echo        This may take a minute on first run...
echo.

python -m pip install --quiet --upgrade flask yt-dlp flask-cors
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Failed to install dependencies.
    echo  Try running this file as Administrator,
    echo  or run manually: pip install flask yt-dlp flask-cors
    echo.
    pause
    exit /b 1
)
echo  [OK] All dependencies installed.

:: ── STEP 4: Check app.py and index.html exist ────────────────────────
echo.
echo  [4/5] Checking project files...

if not exist "%~dp0app.py" (
    echo  [ERROR] app.py not found in: %~dp0
    echo  Make sure START_VORTEXDL.bat is in the same folder as app.py
    pause
    exit /b 1
)

if not exist "%~dp0index.html" (
    echo  [ERROR] index.html not found in: %~dp0
    echo  Make sure START_VORTEXDL.bat is in the same folder as index.html
    pause
    exit /b 1
)

echo  [OK] app.py found.
echo  [OK] index.html found.

:: ── STEP 5: Kill any old process on port 5000 ────────────────────────
echo.
echo  [5/5] Freeing port 5000 if in use...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":5000 "') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo  [OK] Port 5000 is ready.

:: ── START SERVER ─────────────────────────────────────────────────────
echo.
echo  ============================================================
echo   Starting VortexDL server...
echo  ============================================================
echo.

:: Change to the script's directory so relative paths work
cd /d "%~dp0"

:: Start the Flask server in a new window (so closing it stops the server)
start "VortexDL Server" cmd /k "color 0B && echo. && echo  VortexDL Server Running && echo  ======================== && echo  API:      http://localhost:5000 && echo  Website:  Open index.html in your browser && echo. && echo  Keep this window open while using the site. && echo  Close this window to stop the server. && echo. && python app.py"

:: ── WAIT FOR SERVER TO START ─────────────────────────────────────────
echo  Waiting for server to start...
set MAX_WAIT=15
set WAITED=0

:waitloop
timeout /t 1 /nobreak >nul
set /a WAITED+=1

:: Check if server is up by trying to connect
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:5000' -TimeoutSec 1 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 goto server_ready

if %WAITED% lss %MAX_WAIT% goto waitloop

:: Fallback: just wait 3 more seconds and open anyway
timeout /t 3 /nobreak >nul

:server_ready
echo  [OK] Server is up!

:: ── OPEN BROWSER ─────────────────────────────────────────────────────
echo.
echo  Opening VortexDL in your browser...
echo.

:: Open the web UI in the default browser
start "" "http://localhost:5000"

:: ── DONE ─────────────────────────────────────────────────────────────
echo  ============================================================
echo.
echo   VortexDL is running!
echo.
echo   Website : http://localhost:5000  (opened in browser)
echo   API     : http://localhost:5000
echo   Downloads saved to: %~dp0downloads\
echo.
echo   To STOP the server: close the "VortexDL Server" window
echo   To RESTART: run this file again
echo.
echo  ============================================================
echo.
echo  This window can be closed safely.
echo.
pause
