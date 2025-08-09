# 🔥 Firecrawl MCP Telepítési Útmutató Cursor AI-hoz

## Gyors telepítés (Automatikus script)

### macOS/Linux:
```bash
chmod +x install-firecrawl-mcp.sh
./install-firecrawl-mcp.sh
```

### Windows:
```cmd
install-firecrawl-mcp.bat
```

## Manuális telepítés

### 1. Előfeltételek
- ✅ Node.js (https://nodejs.org/)
- ✅ npm
- ✅ Firecrawl API kulcs (https://firecrawl.dev/)
- ✅ Cursor AI (2024 december utáni verzió)

### 2. Firecrawl MCP Server telepítése
```bash
npm install -g @mendable/firecrawl-mcp
```

### 3. Cursor konfigurálása

#### Konfigurációs könyvtár:
- **macOS**: `~/.cursor/`
- **Windows**: `%APPDATA%\Cursor\`
- **Linux**: `~/.cursor/`

#### MCP beállítások (`mcp_settings.json`):
```json
{
  "servers": {
    "firecrawl": {
      "command": "npx",
      "args": ["@mendable/firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "your-api-key-here"
      },
      "timeout": 30000
    }
  }
}
```

### 4. Cursor újraindítása
1. ❌ Zárd be teljesen a Cursor-t (ne csak minimalizáld)
2. 🔄 Indítsd újra
3. ✅ Az MCP server automatikusan elindul

### 5. Tesztelés
Nyiss egy új chat-et és próbáld ki:
```
"Can you scrape the content from example.com?"
```

## Hibaelhárítás

### ❌ "MCP server not found"
- Ellenőrizd, hogy a Cursor verzió támogatja-e az MCP-t (2024 dec. után)
- Győződj meg róla, hogy a `mcp_settings.json` fájl a helyes helyen van

### ❌ "API key invalid"
- Ellenőrizd az API kulcs érvényességét: https://firecrawl.dev/
- Győződj meg róla, hogy van krediteid a fiókodban

### ❌ "Connection timeout"
- Növeld a timeout értéket a konfigurációban (pl. 60000)
- Ellenőrizd a hálózati kapcsolatot

### 🔍 Debug információk
- Nyisd meg a Cursor Developer Tools-t: `View → Toggle Developer Tools`
- Keress MCP-vel kapcsolatos hibaüzeneteket a konzolban

## Alternatív telepítési módok

### Lokális projekt telepítés
```bash
# Projekt könyvtárban
npm init -y
npm install @mendable/firecrawl-mcp
```

Majd módosítsd a `mcp_settings.json`-t:
```json
{
  "servers": {
    "firecrawl": {
      "command": "node",
      "args": ["./node_modules/@mendable/firecrawl-mcp/dist/index.js"],
      "env": {
        "FIRECRAWL_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### Docker alapú telepítés
```dockerfile
FROM node:18-alpine
RUN npm install -g @mendable/firecrawl-mcp
EXPOSE 3000
CMD ["npx", "@mendable/firecrawl-mcp"]
```

## Hasznos funkciók

### Mit tud a Firecrawl MCP?
- 🕷️ **Web scraping**: Teljes weboldalak tartalmának letöltése
- 📄 **Markdown konverzió**: HTML → tiszta Markdown
- 🔗 **Link követés**: Automatikus link crawling
- 📊 **Strukturált adatok**: JSON formátumú kimenet
- 🖼️ **Képek kezelése**: Képek URL-jeinek kinyerése
- 🚫 **Bot védelem**: Cloudflare és más védelmek megkerülése

### Példa használati esetek
```
"Scrape the latest blog posts from techcrunch.com"
"Extract all product information from this e-commerce page"
"Get the main content from this documentation page"
"Find all links on this website's homepage"
```

## Biztonsági megjegyzések
- 🔒 Az API kulcsod bizalmasan kezelendő
- 🚫 Ne commitold a kulcsot verziókezelőbe
- 📝 Használj környezeti változókat éles környezetben
- ⚖️ Tartsd be a webhelyek robots.txt szabályait

## Frissítés
```bash
npm update -g @mendable/firecrawl-mcp
```

Majd indítsd újra a Cursor-t.

---

**További segítség:** Ha problémád van, ellenőrizd a [Firecrawl dokumentációt](https://docs.firecrawl.dev/) vagy a [Cursor MCP útmutatót](https://docs.cursor.com/mcp).