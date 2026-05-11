# Project Memory — Zoo Management Mobile App

## Project Overview
An enterprise-grade zoo mobile application for visitors and staff.
Supports Android and Web platforms.

## Tech Stack
- Flutter 3.x (Dart 3.x)
- Firebase Auth (Email/Password)
- Firebase Firestore (NoSQL database)
- Firebase Storage (animal photos and event images)
- Firebase Crashlytics (error tracking)
- Firebase Remote Config (feature flags)
- State Management: Riverpod 2.x (with code generation)
- Navigation: GoRouter (with auth guards)
- Local Cache: Hive (offline-first for critical data)
- CI/CD: GitHub Actions

---

## Folder Structure

assets/
└── pictures/           ← Logo and static icons ONLY
                          DO NOT store animal or event photos here → use Firebase Storage

lib/
├── cores/
│   ├── constants/      ← app_colors.dart, app_strings.dart
│   ├── routes/         ← app_route.dart (GoRouter + auth guard)
│   ├── services/       ← database_service.dart, seed_service.dart
│   ├── theme/          ← app_theme.dart (uses constants colors, applied in main.dart)
│   ├── utils/          ← shared utility helpers
│   └── widgets/        ← main_wrapper.dart, zoo_bottom_nav.dart (shared ALL features)
│
├── features/
│   ├── admin/          ← Admin-only features (guarded by auth role)
│   │   ├── animals/    ← Admin CRUD for animals
│   │   ├── auth/       ← Admin auth flow
│   │   ├── events/     ← Admin CRUD for events
│   │   ├── maps/       ← Admin map management
│   │   ├── tickets/    ← Admin ticket/booking management
│   │   └── zones/      ← Admin CRUD for zones
│   ├── animals_info/
│   │   ├── models/     ← animal_model.dart
│   │   ├── screens/    ← animal_list_screen.dart, animal_detail_screen.dart
│   │   ├── services/   ← animal_service.dart
│   │   └── widgets/    ← animal_card_widget.dart (this feature only)
│   ├── auth/
│   │   ├── models/     ← user_model.dart
│   │   ├── screens/    ← login_screen.dart, register_screen.dart
│   │   ├── services/   ← auth_service.dart
│   │   └── widgets/
│   ├── booking/
│   │   ├── models/     ← booking_model.dart
│   │   ├── screens/    ← booking_screen.dart, booking_history_screen.dart
│   │   ├── services/   ← booking_service.dart
│   │   └── widgets/
│   ├── events_show/
│   │   ├── models/     ← event_model.dart
│   │   ├── screens/    ← event_list_screen.dart, event_detail_screen.dart
│   │   ├── services/   ← event_service.dart
│   │   └── widgets/
│   ├── home/
│   │   ├── models/     ← home_model.dart
│   │   ├── screens/    ← home_screen.dart
│   │   ├── services/   ← home_service.dart
│   │   └── widgets/    ← menu_button.dart
│   ├── map/
│   │   ├── models/     ← zone_model.dart
│   │   ├── screens/    ← map_screen.dart
│   │   ├── services/   ← map_service.dart
│   │   └── widgets/
│   ├── profile/
│   │   ├── models/
│   │   ├── screens/    ← change_name_screen.dart, change_phone_number_screen.dart, profile_screen.dart
│   │   ├── services/   ← profile_service.dart
│   │   └── widgets/
│
└── main.dart           ← Firebase init, Crashlytics init, ProviderScope, theme applied

---

## Firestore Schema

### 1. Collection: user
Document ID: Firebase Auth UID — NEVER use Auto-ID

| Field       | Type   | Description          | Example          |
|-------------|--------|----------------------|------------------|
| username    | string | Display name         | natt_bua         |
| firstname   | string | First name           | Nathithorn       |
| lastname    | string | Last name            | Buapraserith     |
| email       | string | Registration email   | natt@email.com   |
| phoneNumber | string | Phone number         | 0812345678       |

> SECURITY: Never store passwords in Firestore. Firebase Auth handles all password management.

---

### 2. Collection: zone
Document ID: Auto-ID

| Field    | Type   | Description | Example                 |
|----------|--------|-------------|-------------------------|
| zoneName | string | Zone name   | Bird Zone, Aquatic Zone |

---

### 3. Collection: animal
Document ID: Auto-ID

| Field         | Type      | Description                      | Example                  |
|---------------|-----------|----------------------------------|--------------------------|
| animalName    | string    | Animal name                      | Scarlet Macaw            |
| animalDetail  | string    | Description or history           | Native to South America  |
| animalPicture | string    | Public URL from Firebase Storage | https://.../parrot.jpg   |
| zoneId        | reference | FK → document in zone collection | zone/abc123XYZ           |
| location_x    | int64     | X position of animal on map      | 100                      |
| location_y    | int64     | Y position of animal on map      | 40                       |

---

### 4. Collection: event
Document ID: Auto-ID

| Field        | Type   | Description                | Example                   |
|--------------|--------|----------------------------|---------------------------|
| eventName    | string | Event name                 | Smart Seal Show           |
| eventDetail  | string | Event description          | 2 shows per day...        |
| eventPicture | string | Cover image URL            | https://.../seal_show.png |
| location_x   | int64  | X position of event on map | 100                       |
| location_y   | int64  | Y position of event on map | 10                        |

---

### 5. Collection: booking (CRUD — primary feature)
Document ID: Auto-ID

| Field      | Type      | Description                              | Example               |
|------------|-----------|------------------------------------------|-----------------------|
| userId     | string    | FK: Auth UID of the booking user         | W9aX2... (from Auth)  |
| adultTotal | number    | Number of adults (NOT string)            | 2                     |
| childTotal | number    | Number of children (NOT string)          | 1                     |
| elderTotal | number    | Number of elderly (NOT string)           | 0                     |
| date       | timestamp | Visit date — must use Firebase Timestamp | March 25, 2026        |
| BuffetFood | boolean   | Add-on: Buffet food                      | true                  |
| GuideTour  | boolean   | Add-on: Guide tour                       | false                 |
| GolfCar    | boolean   | Add-on: Golf car                         | false                 |
| status     | string    | Booking status: pending or done          | pending               |

---

### 6. Collection: admin
Document ID: Auto-ID

| Field  | Type      | Description                     | Example                               |
|--------|-----------|---------------------------------|---------------------------------------|
| userId | reference | FK → reference to user document | /user/1Ya6LZ0E11PnXia1UE7NZjxfkTU2   |

> Owner (the admin user themselves) can Create and Read their own document. Update and Delete are NOT allowed from the app.

---

## Architecture Rules

### Layer Responsibilities
| Layer     | Location              | Allowed                          | NOT allowed               |
|-----------|-----------------------|----------------------------------|---------------------------|
| screens/  | features/*/screens/   | Show UI, receive user input      | Logic, Firestore calls    |
| widgets/  | features/*/widgets/   | UI components for this feature   | Logic, Firestore calls    |
| services/ | features/*/services/  | Business logic + Firestore CRUD  | UI code, Navigator        |
| models/   | features/*/models/    | Data structures (freezed)        | Import Firebase directly  |
| cores/    | cores/                | Shared utilities across features | Feature-specific code     |

### Data Flow
```
User action on Screen
    ↓
Screen calls Service (via Riverpod provider)
    ↓
Service performs Firestore read/write via cores/services/database_service.dart
    ↓
Service packs result into Model (freezed)
    ↓
Screen reads updated state from Riverpod provider
```

---

## Conventions
- File names: snake_case always (e.g. animal_model.dart)
- Class names: PascalCase (e.g. AnimalModel)
- Field names are case-sensitive — always match exactly as defined in schema above
- Use freezed for all data models
- Use @riverpod annotation for all providers (code generation)
- Provider naming convention: featureNameProvider
  Examples: animalListProvider, bookingProvider, eventListProvider
- After editing any freezed or riverpod file, always run:
  flutter pub run build_runner build --delete-conflicting-outputs

---

## Feature Flags (Firebase Remote Config)
| Key                | Default | Controls          |
|--------------------|---------|-------------------|
| feature_map_3d     | false   | 3D map view       |
| feature_ar_animals | false   | AR animal overlay |

### Rollback Plan
1. Open Firebase Console → Remote Config
2. Set the flag back to false
3. Publish — takes effect within 1 hour or on next app restart

---

## Firestore Security Rules

### RBAC Summary
| Collection | Create      | Read        | Update      | Delete      | Notes                                        |
|------------|-------------|-------------|-------------|-------------|----------------------------------------------|
| animal     | Admin only  | Everyone    | Admin only  | Admin only  | Public Read, Admin Write                     |
| zone       | Admin only  | Everyone    | Admin only  | Admin only  | Public Read, Admin Write                     |
| event      | Admin only  | Everyone    | Admin only  | Admin only  | Public Read, Admin Write                     |
| map        | Admin only  | Everyone    | Admin only  | Admin only  | Public Read, Admin Write                     |
| booking    | Auth user   | Admin/Owner | Admin/Owner | Admin/Owner | Login สร้างได้, เจ้าของหรือ Admin จัดการได้  |
| user       | Not allowed | Admin/Owner | Owner       | Owner       | Admin หรือเจ้าของอ่านได้, เจ้าของแก้/ลบได้  |
| admin      | Owner       | Owner       | Not allowed | Not allowed | ตัวเองสร้างและอ่านได้, แก้/ลบไม่ได้          |

### Admin Strategy
- Admin identity is determined by checking if the authenticated user's UID exists as a `userId` reference in the `admin` collection
- Admin CRUD for animals, zones, events, maps, and tickets is handled inside `features/admin/`
- Admin features are protected by auth role guard in GoRouter — not accessible to regular users
- Admin collection: Owner can Create and Read only — Update and Delete are forbidden from the app

---

## Do NOT Do
- NEVER write logic or Firestore calls inside screens/
- NEVER store Firebase API keys or secrets in .dart files
- NEVER store passwords in Firestore — Firebase Auth handles this
- NEVER use setState in production code — use Riverpod only
- NEVER create an unbounded ListView — use itemExtent or SliverList
- NEVER commit without passing flutter analyze and flutter test
- NEVER store animal or event photos in assets/ — use Firebase Storage
- NEVER import Firebase directly in models/ layer
- NEVER use Auto-ID for user documents — always use Firebase Auth UID
- NEVER send adultTotal, childTotal, or elderTotal as String — must be Number
- NEVER send date as String — must be Firebase Timestamp
- NEVER send BuffetFood, GuideTour, GolfCar as String — must be Boolean
- NEVER send location_x or location_y as String — must be int64
- NEVER use wrong field name casing — all field names are case-sensitive (e.g. BuffetFood not buffetfood)
- NEVER update or delete documents in the admin collection from the app

---

## Crashlytics Integration
- Initialize in main.dart before runApp()
- Catch and log errors in every service file
- Attach custom keys: userId, screen_name
- Confirm setup by triggering a deliberate test crash
