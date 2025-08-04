# SnappyCards Felhasználói Szerepkörök és Szabályrendszer

## 📋 Áttekintés

A SnappyCards rendszer három fő felhasználói szerepkört támogat, mindegyik különböző jogosultságokkal és képességekkel. A rendszer rugalmas felépítése lehetővé teszi, hogy a diákok függetlenül regisztrálhassanak, majd opcionálisan kapcsolódhassanak tanárokhoz, míg a tanárok lehetnek függetlenek (magántanárok) vagy iskola által regisztráltak.

---

## 🎓 DIÁK (Student)

### Regisztrációs típus:
- **Független regisztráció** - önállóan regisztrálnak a rendszerbe
- **Nincs automatikus iskola vagy tanár kapcsolat**

### Alapértelmezett állapot:
- `school_id = NULL` (nincs iskolához rendelve)
- `user_role = 'student'`
- **Önálló tanulás módban** kezdik

### Képességek:
- ✅ **Önálló flashcard tanulás**
- ✅ **Saját szettek létrehozása** (privát használatra)
- ✅ **Nyilvános szettek elérése** (ha vannak)
- ✅ **Saját tanulási statisztikák**
- ✅ **Tanárhoz csatlakozás meghívó kóddal**

### Tanárhoz csatlakozás:
- **Meghívó kód** alapján kapcsolódhatnak tanárhoz
- A kód egy konkrét tanár vagy osztály/csoport specifikus
- Csatlakozás után hozzáférnek a tanár által készített szettekhez

### Adatbázis séma:
```sql
user_profiles:
- id: UUID (foreign key to auth.users)
- first_name: TEXT
- last_name: TEXT  
- user_role: 'student'
- school_id: NULL (alapértelmezett)
- created_at: TIMESTAMP
- is_mock: BOOLEAN
- phone: TEXT (opcionális)
```

---

## 👨‍🏫 TANÁR (Teacher)

A tanárok **két típusra** oszthatók fel jogosultságaik és regisztrációjuk alapján:

### A) MAGÁNTANÁR (Független tanár)

#### Regisztrációs típus:
- **Önálló regisztráció** - saját maguk regisztrálnak
- **Nincs iskola kapcsolat**

#### Alapértelmezett állapot:
- `school_id = NULL`
- `user_role = 'teacher'`

#### Képességek:
- ✅ **Tetszőleges számú csoport/osztály létrehozása**
- ✅ **Tetszőleges számú diák meghívása** (kód alapján)
- ✅ **Flashcard szettek készítése** (tanítási + privát)
- ✅ **Privát szettek** (tanítás nélkül, csak saját használat)
- ✅ **Teljes szabadság** a tanítási struktúrában
- ✅ **Saját statisztikák** (diákok, szettek, haladás)

### B) ISKOLA TANÁR (Iskolához tartozó tanár)

#### Regisztrációs típus:
- **Iskola admin regisztrálja** őket
- **Email + jelszó** alapú regisztráció
- **Automatikus iskola kapcsolat**

#### Alapértelmezett állapot:
- `school_id = [iskola_id]` (automatikusan beállítva)
- `user_role = 'teacher'`

#### Képességek:
- ✅ **Osztályok/csoportok létrehozása** az iskolán belül
- ✅ **Diákok meghívása** kód alapján
- ✅ **Flashcard szettek készítése** (tanítási + privát)
- ✅ **Privát szettek** (tanítás nélkül, csak saját használat)
- ✅ **Korlátozott az iskolai kereteken belül**
- ⚠️ **Iskola admin teljes hozzáféréssel** a tanár adataihoz

### Közös tanári képességek:

#### Osztály/Csoport kezelés:
- **Osztályok létrehozása** különböző tantárgyakhoz
- **Meghívó kódok generálása** diákoknak
- **Diákok hozzárendelése** osztályokhoz
- **Osztály statisztikák** követése

#### Flashcard szett kezelés:
- **Szettek létrehozása** különböző témákhoz
- **CEFR szintek** beállítása (A1, A2, B1, B2, C1, C2)
- **Szettek hozzárendelése** osztályokhoz
- **Kártyák készítése** szettekhez

#### Diák kezelés:
- **Meghívó kódok** küldése emailben
- **Diák haladás** nyomon követése
- **Tanulási statisztikák** megtekintése

### Adatbázis séma:
```sql
user_profiles:
- id: UUID
- first_name: TEXT
- last_name: TEXT
- user_role: 'teacher'
- school_id: UUID vagy NULL (magántanár esetén)
- created_at: TIMESTAMP
- is_mock: BOOLEAN
- phone: TEXT
- status: TEXT ('active', 'archived')
- note: TEXT (iskola admin megjegyzései)
```

---

## 🏫 ISKOLA ADMIN (School Administrator)

### Regisztrációs típus:
- **Külön regisztrációs kategória**
- **Iskola létrehozásával** egy időben
- **Legmagasabb szintű jogosultságok**

### Alapértelmezett állapot:
- `user_role = 'school_admin'`
- `school_id = [saját_iskola_id]`

### Teljes iskola irányítás:

#### Tanár kezelés:
- ✅ **Tanárok regisztrálása** (név, email, auto-generált jelszó)
- ✅ **Welcome emailek küldése** tanároknak
- ✅ **Tanárok szerkesztése** (státusz, megjegyzések)
- ✅ **Tanárok archiválása/törlése**
- ✅ **Tanár státusz kezelés** (aktív/archivált)

#### Osztály kezelés:
- ✅ **Osztályok létrehozása**
- ✅ **Tanárok hozzárendelése** osztályokhoz
- ✅ **Időintervallumok** beállítása (tanár-osztály kapcsolatokhoz)
- ✅ **Osztály átszervezés**

#### Teljes rálátás:
- ✅ **Összes szett** (az iskola tanáraitól)
- ✅ **Összes diák** (iskolai tanárok diákjai)
- ✅ **Összes szókártya**
- ✅ **Teljes statisztikák** (tanárok, diákok, osztályok, szettek)
- ✅ **Haladási jelentések**

#### Iskola beállítások:
- ✅ **Iskola adatok** szerkesztése (név, cím, telefon)
- ✅ **Admin profil** kezelése
- ✅ **Iskola szintű** konfigurációk

### Adatbázis séma:
```sql
user_profiles:
- id: UUID
- first_name: TEXT
- last_name: TEXT
- user_role: 'school_admin'
- school_id: UUID (saját iskola)
- created_at: TIMESTAMP
- is_mock: BOOLEAN
- phone: TEXT

schools:
- id: UUID (PRIMARY KEY)
- name: TEXT
- address: TEXT
- phone: TEXT
- is_mock: BOOLEAN
- created_at: TIMESTAMP
```

---

## 🔗 Kapcsolati rendszer

### Diák ↔ Tanár kapcsolat:
- **Meghívó kód alapú** rendszer
- **Nem közvetlen** adatbázis kapcsolat
- **Rugalmas** csatlakozás/kilépés

### Tanár ↔ Iskola kapcsolat:
- **school_id** alapú kapcsolat
- **Magántanár**: `school_id = NULL`
- **Iskola tanár**: `school_id = [iskola_id]`

### Adatstruktúra:
```sql
-- Meghívó kódok táblája (jövőbeli fejlesztés)
teacher_student_invites:
- id: UUID
- invite_code: TEXT (egyedi kód)
- teacher_id: UUID
- classroom_id: UUID (opcionális)
- expires_at: TIMESTAMP
- used_by_student_id: UUID (NULL amíg nincs használva)
- created_at: TIMESTAMP
- is_mock: BOOLEAN

-- Tanár-osztály hozzárendelések
teacher_classroom_assignments:
- teacher_id: UUID
- classroom_id: UUID
- start_date: DATE
- end_date: DATE (opcionális)
- created_at: TIMESTAMP
- is_mock: BOOLEAN
```

---

## 📊 Jogosultsági mátrix

| Képesség | Diák | Magántanár | Iskola Tanár | Iskola Admin |
|----------|------|------------|--------------|--------------|
| Önálló regisztráció | ✅ | ✅ | ❌ | ✅ |
| Flashcard tanulás | ✅ | ✅ | ✅ | ✅ |
| Szett létrehozás | ✅ (saját) | ✅ (saját + tanítási) | ✅ (tanítási) | ✅ |
| Privát szettek | ✅ (csak saját) | ✅ (tanítás nélkül) | ✅ (tanítás nélkül) | ✅ |
| Osztály létrehozás | ❌ | ✅ | ✅ (iskolán belül) | ✅ |
| Diák meghívás (kód) | ❌ | ✅ | ✅ | ✅ |
| Tanár regisztráció | ❌ | ❌ | ❌ | ✅ |
| Iskola beállítások | ❌ | ❌ | ❌ | ✅ |
| Statisztikák | Saját | Saját | Saját | **Iskola szintű** |
| Korlátlan csoportok | ❌ | ✅ | Iskolán belül | Iskola szintű |
| Teljes rálátás | ❌ | Saját adatok | Saját adatok | **Iskola összes adata** |

---

## 🎯 Kulcs elvek

1. **Rugalmasság**: Minden szerepkör működhet függetlenül
2. **Opcionális kapcsolatok**: Senki sem kényszerített kapcsolatokra  
3. **Fokozatos jogosultságok**: Diák < Tanár < Iskola Admin
4. **Adatvédelem**: Mindenki csak a saját adataihoz fér hozzá (+ jogosultságok szerint)
5. **Skálázhatóság**: Egy diáktól több ezer fős iskoláig

---

## 🔄 Tipikus használati esetek

### Eset 1: Független diák
1. Diák regisztrál → önálló tanulás
2. Opcionálisan csatlakozik tanárhoz kód alapján

### Eset 2: Magántanár
1. Tanár regisztrál → létrehozza csoportjait
2. Meghív diákokat → tanít

### Eset 3: Iskola integráció
1. Iskola admin regisztrál → létrehozza iskolát
2. Admin regisztrál tanárokat → emailek
3. Tanárok létrehozzák osztályaikat → meghívják diákjaikat
4. Admin teljes rálátással irányít

Ez a szabályrendszer biztosítja, hogy a SnappyCards rugalmasan alkalmazkodjon minden oktatási környezethez, a magántanároktól a nagy iskolákig.