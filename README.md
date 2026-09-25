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

1. Requires PHP 7.4+ and MySQL (XAMPP / WAMP / MAMP / LAMP all work).
2. Copy the `backend/` folder into your server's web root, e.g.
   `C:/xampp/htdocs/dota-heroes-app/backend`.
3. Import `backend/sql/dota_heroes.sql` into MySQL (via phpMyAdmin or CLI). This
   creates the `dota_heroes_db` database, the `heroes` table, and seeds 8 real heroes.
4. Update credentials in `backend/config/database.php` if your MySQL user/password differ.
5. Test the API in a browser or Postman:
   - `GET  http://localhost/dota-heroes-app/backend/heroes/read.php`
   - `GET  http://localhost/dota-heroes-app/backend/heroes/read_one.php?id=1`
   - `POST http://localhost/dota-heroes-app/backend/heroes/create.php`
   - `PUT  http://localhost/dota-heroes-app/backend/heroes/update.php`
   - `DELETE http://localhost/dota-heroes-app/backend/heroes/delete.php`

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
