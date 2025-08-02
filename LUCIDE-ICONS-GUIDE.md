# 🎨 Lucide Icons - Használati útmutató

## 📚 Globális CSS osztályok

A `styles.css` fájlban definiált Lucide Icons osztályok használata az egész projektben.

## 🔧 Alapvető használat

### SVG ikon HTML struktúra:
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M5 12h14"/>
    <path d="m12 5v14"/>
</svg>
```

## 📏 Méret osztályok

```html
<!-- Extra small (14px) -->
<svg class="lucide-icon icon-xs" viewBox="0 0 24 24">...</svg>

<!-- Small (16px) -->
<svg class="lucide-icon icon-sm" viewBox="0 0 24 24">...</svg>

<!-- Medium (20px) - DEFAULT -->
<svg class="lucide-icon icon-md" viewBox="0 0 24 24">...</svg>

<!-- Large (24px) -->
<svg class="lucide-icon icon-lg" viewBox="0 0 24 24">...</svg>

<!-- Extra large (28px) -->
<svg class="lucide-icon icon-xl" viewBox="0 0 24 24">...</svg>
```

## 🎨 Szín osztályok

```html
<!-- Elsődleges szín -->
<svg class="lucide-icon icon-primary" viewBox="0 0 24 24">...</svg>

<!-- Siker (zöld) -->
<svg class="lucide-icon icon-success" viewBox="0 0 24 24">...</svg>

<!-- Figyelmeztetés (narancs) -->
<svg class="lucide-icon icon-warning" viewBox="0 0 24 24">...</svg>

<!-- Veszély (piros) -->
<svg class="lucide-icon icon-danger" viewBox="0 0 24 24">...</svg>

<!-- Információ (kék) -->
<svg class="lucide-icon icon-info" viewBox="0 0 24 24">...</svg>

<!-- Másodlagos (szürke) -->
<svg class="lucide-icon icon-secondary" viewBox="0 0 24 24">...</svg>

<!-- Fehér -->
<svg class="lucide-icon icon-white" viewBox="0 0 24 24">...</svg>

<!-- Halványított -->
<svg class="lucide-icon icon-muted" viewBox="0 0 24 24">...</svg>
```

## ✨ Hover effektek

```html
<!-- Nagyítás hover-re -->
<svg class="lucide-icon icon-hover" viewBox="0 0 24 24">...</svg>

<!-- Forgás hover-re -->
<svg class="lucide-icon icon-rotate" viewBox="0 0 24 24">...</svg>

<!-- Forgó animáció -->
<svg class="lucide-icon icon-spin" viewBox="0 0 24 24">...</svg>
```

## 🔲 Gomb kombinációk

### Szöveges gomb ikonnal:
```html
<button class="btn-icon">
    <svg class="lucide-icon" viewBox="0 0 24 24">
        <path d="M5 12h14"/>
        <path d="m12 5v14"/>
    </svg>
    Új elem
</button>
```

### Akció gomb (dashboard stílus):
```html
<!-- Hozzáadás gomb -->
<button class="btn-action btn-add">
    <svg class="lucide-icon" viewBox="0 0 24 24">
        <path d="M5 12h14"/>
        <path d="m12 5v14"/>
    </svg>
</button>

<!-- Szerkesztés gomb -->
<button class="btn-action btn-edit">
    <svg class="lucide-icon" viewBox="0 0 24 24">
        <path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>
        <path d="m15 5 4 4"/>
    </svg>
</button>

<!-- Lista gomb -->
<button class="btn-action btn-list">
    <svg class="lucide-icon" viewBox="0 0 24 24">
        <path d="M8 6h13"/>
        <path d="M8 12h13"/>
        <path d="M8 18h13"/>
        <path d="M3 6h.01"/>
        <path d="M3 12h.01"/>
        <path d="M3 18h.01"/>
    </svg>
</button>
```

## 📖 Gyakori ikonok - SVG path-ok

### ➕ Plus (Hozzáadás):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M5 12h14"/>
    <path d="m12 5v14"/>
</svg>
```

### ✏️ Edit (Szerkesztés):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>
    <path d="m15 5 4 4"/>
</svg>
```

### 📄 List (Lista):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M8 6h13"/>
    <path d="M8 12h13"/>
    <path d="M8 18h13"/>
    <path d="M3 6h.01"/>
    <path d="M3 12h.01"/>
    <path d="M3 18h.01"/>
</svg>
```

### ⬇️ Download (Letöltés):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
    <polyline points="7,10 12,15 17,10"/>
    <line x1="12" x2="12" y1="15" y2="3"/>
</svg>
```

### 🗑️ Trash (Törlés):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="m3 6 3 18h12l3-18"/>
    <path d="M8 6V4c0-1 1-2 2-2h4c0 1 1 2 2 2v2"/>
    <line x1="10" x2="10" y1="11" y2="17"/>
    <line x1="14" x2="14" y1="11" y2="17"/>
</svg>
```

### 🚪 Log Out (Kilépés):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
    <polyline points="16,17 21,12 16,7"/>
    <line x1="21" x2="9" y1="12" y2="12"/>
</svg>
```

### ⚙️ Settings (Beállítások):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
    <circle cx="12" cy="12" r="3"/>
</svg>
```

### 🔍 Search (Keresés):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <circle cx="11" cy="11" r="8"/>
    <path d="m21 21-4.35-4.35"/>
</svg>
```

### ❌ X (Bezárás):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="M18 6 6 18"/>
    <path d="m6 6 12 12"/>
</svg>
```

### ✅ Check (Pipa):
```html
<svg class="lucide-icon" viewBox="0 0 24 24">
    <path d="m9 12 2 2 4-4"/>
</svg>
```

## 🚀 Gyakorlati példák

### Dashboard akció gombok:
```html
<div class="action-buttons">
    <button class="btn-action btn-add" title="Új kártya">
        <svg class="lucide-icon" viewBox="0 0 24 24">
            <path d="M5 12h14"/>
            <path d="m12 5v14"/>
        </svg>
    </button>
    <button class="btn-action btn-edit" title="Szerkesztés">
        <svg class="lucide-icon" viewBox="0 0 24 24">
            <path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>
            <path d="m15 5 4 4"/>
        </svg>
    </button>
</div>
```

### Szöveges gomb ikonnal:
```html
<button class="btn-icon">
    <svg class="lucide-icon icon-sm" viewBox="0 0 24 24">
        <path d="M5 12h14"/>
        <path d="m12 5v14"/>
    </svg>
    Új elem hozzáadása
</button>
```

## 💡 Tippek

1. **Használd a `currentColor`-t**: A stroke="currentColor" automatikusan örökli a szülő elem színét
2. **Méret konzisztencia**: Tartsd egységesen a stroke-width értékeket a mérethez képest
3. **Accessibility**: Mindig adj `title` attribútumot a gombokhoz
4. **Performance**: Az SVG inline használata gyorsabb, mint külső fájlok
5. **Responsive**: A CSS osztályok automatikusan skáláznak

## 🔗 Forrás

- **Lucide Icons**: https://lucide.dev/
- **1,433+ ingyenes ikon**
- **Open source (ISC license)**
- **Konzisztens 24x24 grid rendszer**