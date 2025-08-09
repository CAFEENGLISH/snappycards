#!/bin/bash

# Firecrawl MCP telepítő script Cursor AI-hoz
# Használat: chmod +x install-firecrawl-mcp.sh && ./install-firecrawl-mcp.sh

echo "🔥 Firecrawl MCP telepítő script indítása..."

# Ellenőrizzük, hogy Node.js telepítve van-e
if ! command -v node &> /dev/null; then
    echo "❌ Node.js nincs telepítve. Kérlek telepítsd először a Node.js-t!"
    echo "Letöltés: https://nodejs.org/"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm nincs telepítve. Kérlek telepítsd először az npm-et!"
    exit 1
fi

echo "✅ Node.js és npm telepítve"

# Firecrawl MCP telepítése
echo "📦 Firecrawl MCP telepítése..."
npm install -g firecrawl-mcp

if [ $? -ne 0 ]; then
    echo "❌ Hiba történt a Firecrawl MCP telepítése közben"
    exit 1
fi

echo "✅ Firecrawl MCP sikeresen telepítve"

# Cursor konfigurációs könyvtár meghatározása
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CONFIG_DIR="$HOME/.cursor"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    CONFIG_DIR="$APPDATA/Cursor"
else
    # Linux
    CONFIG_DIR="$HOME/.cursor"
fi

echo "📂 Cursor konfigurációs könyvtár: $CONFIG_DIR"

# Konfigurációs könyvtár létrehozása ha nem létezik
mkdir -p "$CONFIG_DIR"

# Firecrawl API kulcs bekérése
echo ""
echo "🔑 Kérlek add meg a Firecrawl API kulcsodat:"
echo "   (Ha nincs még, szerezz egyet itt: https://firecrawl.dev)"
read -s -p "API kulcs: " FIRECRAWL_API_KEY
echo ""

if [ -z "$FIRECRAWL_API_KEY" ]; then
    echo "❌ API kulcs megadása kötelező!"
    exit 1
fi

# MCP konfigurációs fájl létrehozása
MCP_CONFIG_FILE="$CONFIG_DIR/mcp_settings.json"

echo "📝 MCP konfigurációs fájl létrehozása: $MCP_CONFIG_FILE"

# Ellenőrizzük, hogy már létezik-e a fájl
if [ -f "$MCP_CONFIG_FILE" ]; then
    echo "⚠️  Már létezik MCP konfigurációs fájl. Biztonsági mentés készítése..."
    cp "$MCP_CONFIG_FILE" "$MCP_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Biztonsági mentés készült: $MCP_CONFIG_FILE.backup.*"
fi

# Új konfigurációs fájl létrehozása
cat > "$MCP_CONFIG_FILE" << EOF
{
  "servers": {
    "firecrawl": {
      "command": "npx",
      "args": ["firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
      },
      "timeout": 30000
    }
  }
}
EOF

echo "✅ MCP konfigurációs fájl sikeresen létrehozva"

# Ellenőrizzük a telepítést
echo ""
echo "🧪 Telepítés ellenőrzése..."
FIRECRAWL_API_KEY="$FIRECRAWL_API_KEY" npx firecrawl-mcp --version 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Firecrawl MCP sikeresen működik"
else
    echo "⚠️  Firecrawl MCP telepítve, de a teszt nem sikerült (ez normális lehet)"
fi

echo ""
echo "🎉 Telepítés befejezve!"
echo ""
echo "📋 Mit kell még tenned:"
echo "1. 🔄 Indítsd újra a Cursor AI-t TELJESEN (kilépés + újraindítás)"
echo "2. 🗨️  Nyiss egy új chat-et Cursor-ban"
echo "3. 🧪 Teszteld: 'Can you scrape the content from example.com?'"
echo ""
echo "🔧 Ha problémád van:"
echo "   - Ellenőrizd a Cursor Developer Tools-ban a hibaüzeneteket"
echo "   - Győződj meg róla, hogy a Cursor friss verziójú (2024 december után)"
echo "   - Ellenőrizd az API kulcs érvényességét: https://firecrawl.dev"
echo ""
echo "📁 Konfigurációs fájl helye: $MCP_CONFIG_FILE"