@echo off
setlocal enabledelayedexpansion

REM Firecrawl MCP telepítő script Cursor AI-hoz Windows-ra
REM Használat: install-firecrawl-mcp.bat

echo 🔥 Firecrawl MCP telepítő script indítása...

REM Ellenőrizzük, hogy Node.js telepítve van-e
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js nincs telepítve. Kérlek telepítsd először a Node.js-t!
    echo Letöltés: https://nodejs.org/
    pause
    exit /b 1
)

npm --version >nul 2>&1
if errorlevel 1 (
    echo ❌ npm nincs telepítve. Kérlek telepítsd először az npm-et!
    pause
    exit /b 1
)

echo ✅ Node.js és npm telepítve

REM Firecrawl MCP telepítése
echo 📦 Firecrawl MCP telepítése...
npm install -g @mendable/firecrawl-mcp

if errorlevel 1 (
    echo ❌ Hiba történt a Firecrawl MCP telepítése közben
    pause
    exit /b 1
)

echo ✅ Firecrawl MCP sikeresen telepítve

REM Cursor konfigurációs könyvtár meghatározása
set "CONFIG_DIR=%APPDATA%\Cursor"

echo 📂 Cursor konfigurációs könyvtár: %CONFIG_DIR%

REM Konfigurációs könyvtár létrehozása ha nem létezik
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

REM Firecrawl API kulcs bekérése
echo.
echo 🔑 Kérlek add meg a Firecrawl API kulcsodat:
echo    (Ha nincs még, szerezz egyet itt: https://firecrawl.dev)
set /p "FIRECRAWL_API_KEY=API kulcs: "

if "%FIRECRAWL_API_KEY%"=="" (
    echo ❌ API kulcs megadása kötelező!
    pause
    exit /b 1
)

REM MCP konfigurációs fájl létrehozása
set "MCP_CONFIG_FILE=%CONFIG_DIR%\mcp_settings.json"

echo 📝 MCP konfigurációs fájl létrehozása: %MCP_CONFIG_FILE%

REM Ellenőrizzük, hogy már létezik-e a fájl
if exist "%MCP_CONFIG_FILE%" (
    echo ⚠️  Már létezik MCP konfigurációs fájl. Biztonsági mentés készítése...
    for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set mydate=%%c%%a%%b
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set mytime=%%a%%b
    copy "%MCP_CONFIG_FILE%" "%MCP_CONFIG_FILE%.backup.!mydate!_!mytime!"
    echo ✅ Biztonsági mentés készült
)

REM Új konfigurációs fájl létrehozása
(
echo {
echo   "servers": {
echo     "firecrawl": {
echo       "command": "npx",
echo       "args": ["@mendable/firecrawl-mcp"],
echo       "env": {
echo         "FIRECRAWL_API_KEY": "%FIRECRAWL_API_KEY%"
echo       },
echo       "timeout": 30000
echo     }
echo   }
echo }
) > "%MCP_CONFIG_FILE%"

echo ✅ MCP konfigurációs fájl sikeresen létrehozva

echo.
echo 🎉 Telepítés befejezve!
echo.
echo 📋 Mit kell még tenned:
echo 1. 🔄 Indítsd újra a Cursor AI-t TELJESEN (kilépés + újraindítás)
echo 2. 🗨️  Nyiss egy új chat-et Cursor-ban
echo 3. 🧪 Teszteld: 'Can you scrape the content from example.com?'
echo.
echo 🔧 Ha problémád van:
echo    - Ellenőrizd a Cursor Developer Tools-ban a hibaüzeneteket
echo    - Győződj meg róla, hogy a Cursor friss verziójú (2024 december után)
echo    - Ellenőrizd az API kulcs érvényességét: https://firecrawl.dev
echo.
echo 📁 Konfigurációs fájl helye: %MCP_CONFIG_FILE%
echo.
pause