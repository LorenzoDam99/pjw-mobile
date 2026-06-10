# Ciclo — Mobile (Android)

App Flutter del servizio di noleggio bici. Punta allo stesso backend del frontend web.

- **BE**: `https://project-work-template-be.onrender.com/api`
- **Platform**: Android only (light mode)
- **Stack**: Flutter 3, Riverpod 2, Dio, go_router, SharedPreferences (token), `intl` (it_IT)

## Setup

```
flutter pub get
flutter run -d <android-device>
```

Per la build release:
```
flutter build apk --release
```

## Struttura

```
lib/
├── main.dart                        bootstrap, theme, locale
├── core/
│   ├── api/api_client.dart          Dio + refresh interceptor
│   ├── storage/token_storage.dart   SharedPreferences (parity col web)
│   ├── models/models.dart           User, Retailer, Bicycle, Stock, Booking, ecc.
│   ├── router/app_router.dart       go_router con auth guard
│   ├── theme/app_theme.dart         Material 3 light, Inter
│   ├── utils/jwt.dart               decode JWT senza dipendenze
│   └── providers.dart               Riverpod root
└── features/
    ├── auth/                        login, register, OTP
    ├── bookings/                    list + detail
    ├── catalog/                     retailers, bikes, types, sizes, accessories, insurances
    └── new_booking/                 multi-bike cart, mode tabs, time slots
```

## Note

- Token JWT in SharedPreferences (coerenza col web, niente secure storage).
- Una `POST /bookings` per ogni unità del carrello — multi-bike e quantità si traducono in chiamate parallele.
- Slot di ritiro a fasce orarie da 09:00 a 18:00 (HH:00, minuti = 00).
- Riconsegna sempre alle 18:00 della data scelta.
- Cancellazione prenotazione via `PATCH /bookings/:id` con `status: "cancelled"`, ammessa solo se `pending` e ≥48h dal ritiro.
