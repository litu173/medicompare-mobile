# MediCompare BD — Flutter app (phase 2)

Android and iOS client for the Next.js backend in `../web`. Same screens as the mobile web: Home, Search (grouped
by equivalence, cheapest first), Product, Generic, Companies, Cart, Checkout (guest or account, COD), Order
confirmation/tracking, Login/Register and Account.

## Run

```bash
cd ../web && npm run dev          # backend on :3000
cd ../mobile && flutter run       # iOS simulator uses localhost:3000, Android emulator 10.0.2.2:3000
flutter run --dart-define=API_BASE=https://your-host   # any other backend
```

## Structure

- `lib/api.dart` — `/api/v1` client; sends the session token as `Authorization: Bearer`
- `lib/models.dart` — JSON models; `lib/format.dart` — taka/price helpers (mirrors `web/src/lib/format.ts`)
- `lib/state.dart` — `AuthModel` (token in Keychain/Keystore via flutter_secure_storage), `CartModel`
  (shared_preferences; prices always re-quoted by `POST /cart/quote`), `DeviceOrders` (guest order codes + phone
  for tracking), `MetaModel` (divisions/districts, payment methods), `TabsModel`
- `lib/screens/` — `catalog.dart` (home, search, product, generic, companies), `shop.dart` (cart, checkout,
  order, track), `account.dart` (login, register, account, addresses), `shell.dart` (bottom tabs, one navigator each)

Guest orders are viewable with `GET /api/v1/orders/:code?phone=`; the app remembers code + phone on the device.
Prescription upload and Google sign-in are web-only for now.
