# Dota Heroes — Mobile App + Custom REST API + External API Integration

Midterm Exam Project: **Mobile Application, Custom REST API & External API Integration**
Assigned Topic: **Dota Heroes**

## Overview

This project has two parts:

1. **Custom REST API** (`/backend`) — a PHP + MySQL REST API with full CRUD for a
   `heroes` table (Dota 2 heroes: name, primary attribute, attack type, roles, image, lore).
2. **Mobile App** (`/mobile`) — a Flutter app that:
   - Consumes the custom REST API for full CRUD (list/grid, detail view, create form,
     edit form, delete with confirmation).
   - Consumes the **News API** (third-party public API) to show a live "Dota 2 News" feed.

## Third-Party API Used

- **Name:** News API
- **URL:** https://newsapi.org/
- **Endpoint used:** `GET https://newsapi.org/v2/everything?q=Dota 2&language=en&sortBy=publishedAt&apiKey=YOUR_KEY`
- **Why:** Displays a live, auto-refreshing feed of recent Dota 2 / esports headlines
  as a companion dashboard next to the hero roster.
- Get a free key at https://newsapi.org/register and paste it into
  `mobile/lib/services/news_service.dart` (`_apiKey`).

## Backend Setup (PHP + MySQL)

This backend can run either on a local server (XAMPP/WAMP/MAMP) **or** on free/shared
hosting (e.g. Freehostia). Shared hosting is recommended for this exam since it gives
your API a public URL that works from any device with no `10.0.2.2`/LAN-IP juggling.

### Option A — Shared hosting (e.g. Freehostia)

1. In your hosting control panel, create a MySQL database (the host usually
   auto-names it after your account, e.g. `youracct_dota-heroes`, and creates a
   matching DB user — note the **host**, **db name**, **username**, **password**).
2. Open phpMyAdmin from the panel, click into your database in the left sidebar
   (so it's selected), then **Import** → choose `backend/sql/dota_heroes.sql` → Go.
   (This file only contains `CREATE TABLE` + seed data — no `CREATE DATABASE`
   statement, since shared hosting doesn't allow that.)
3. Upload the entire `backend/` folder to your hosting account's `public_html`
   (via File Manager or FTP/FileZilla).
4. Edit `backend/config/database.php` with your real host/db name/username/password.
5. Test in a browser: `http://yourdomain.tld/backend/heroes/read.php` — you should
   see a JSON array of heroes.
6. Point the Flutter app's `baseUrl` (in `mobile/lib/services/api_service.dart`) at
   `http://yourdomain.tld/backend/heroes`.

### Option B — Local server (XAMPP/WAMP/MAMP/LAMP)

1. Copy the `backend/` folder into your server's web root, e.g.
   `C:/xampp/htdocs/dota-heroes-app/backend`.
2. Import `backend/sql/dota_heroes.sql` into a database you create yourself
   (e.g. `dota_heroes_db`) via phpMyAdmin.
3. Update credentials in `backend/config/database.php` to match.
4. Test the API in a browser or Postman:
   - `GET  http://localhost/dota-heroes-app/backend/heroes/read.php`
   - `GET  http://localhost/dota-heroes-app/backend/heroes/read_one.php?id=1`
   - `POST http://localhost/dota-heroes-app/backend/heroes/create.php`
   - `PUT  http://localhost/dota-heroes-app/backend/heroes/update.php`
   - `DELETE http://localhost/dota-heroes-app/backend/heroes/delete.php`
   - With this option, the Flutter app's `baseUrl` needs the emulator/device rules
     described below (`10.0.2.2`, `localhost`, or LAN IP).

### Endpoint Reference

| Operation | Method | Endpoint | Body (JSON) |
|---|---|---|---|
| List all heroes | GET | `/heroes/read.php` | — |
| Get one hero | GET | `/heroes/read_one.php?id={id}` | — |
| Create hero | POST | `/heroes/create.php` | `name, localized_name, primary_attr, attack_type, roles, img_url, lore` |
| Update hero | PUT | `/heroes/update.php` | same as above + `id` |
| Delete hero | DELETE | `/heroes/delete.php` | `id` |

## Mobile App Setup (Flutter)

1. Install Flutter SDK (https://flutter.dev).
2. `cd mobile`
3. `flutter pub get`
4. In `lib/services/api_service.dart`, set `baseUrl` to point at your backend:
   - Android **emulator** + backend on your PC → `http://10.0.2.2/dota-heroes-app/backend/heroes`
   - iOS **simulator** → `http://localhost/dota-heroes-app/backend/heroes`
   - **Physical device** → `http://<your-computer-LAN-IP>/dota-heroes-app/backend/heroes`
5. In `lib/services/news_service.dart`, paste your News API key into `_apiKey`.
6. Run: `flutter run`

## Features Checklist

- [x] GET — heroes displayed in a responsive grid; tap opens a detail screen
- [x] POST — validated create form; list refreshes after saving
- [x] PUT — pre-populated edit form updates the record
- [x] DELETE — confirmation dialog before removing a hero
- [x] External API — Dota 2 news feed via News API, tap to open full article
- [x] Input validation (required fields, URL format check)
- [x] Error handling & loading states on every network call

## Folder Structure

```
dota-heroes-app/
├── backend/                # PHP REST API
│   ├── config/
│   │   ├── database.php
│   │   └── cors.php
│   ├── heroes/
│   │   ├── create.php
│   │   ├── read.php
│   │   ├── read_one.php
│   │   ├── update.php
│   │   └── delete.php
│   └── sql/
│       └── dota_heroes.sql
├── mobile/                  # Flutter app
│   └── lib/
│       ├── models/
│       ├── services/
│       ├── screens/
│       ├── widgets/
│       └── main.dart
└── README.md
```
