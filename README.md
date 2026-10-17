# সাশ্রয় · Sashroy: Flutter app (Android & iOS)

_Formerly MediCompare BD._

Android and iOS client for the Next.js backend in `../web`. Same screens as the mobile web: Home, Search (grouped
by equivalence, cheapest first), Product, Generic, Companies, Cart, Checkout (guest or account, COD), Order
confirmation/tracking, Login/Register and Account.

## Design & features

- **Look:** emerald-and-ivory "luxury" theme with gold accents (see `lib/theme.dart`), Fraunces for headings and prices, Plus Jakarta Sans for UI and Hind Siliguri for Bangla (via `google_fonts`), soft cards and a floating bottom bar.
- **Illustrations:** custom vector scenes of Bangladeshi customers in `assets/illustrations/` (onboarding, empty states, order success, community).
- **Onboarding:** three slides on first launch.
- **Savings tracker:** money saved against the typical price (the median of equivalent brands), from `POST /api/v1/savings`. Shown on Home, Orders and Account, with a Share button.
- **Switch & save:** in the cart, one tap (or "Switch all") swaps an item for its cheapest in-stock equivalent.
- **Ordering:** searchable pickers for division, district and thana. A vertical order tracker with times, a call button for the rider, and a "Talk to a pharmacist" option when the store sets a help line.
- **Sharing:** invite your family through the system share sheet.

## Run

```bash
cd ../web && npm run dev          # backend on :3000
cd ../mobile && flutter run       # iOS simulator uses localhost:3000, Android emulator 10.0.2.2:3000
flutter run --dart-define=API_BASE=https://your-host   # any other backend
```

## Test on an Android phone

1. Download and install the APK (allow "Install unknown apps" for your browser when Android asks):
   `https://github.com/<owner>/<repo>/releases/download/latest-android/medicompare.apk`
2. On your computer, run the website so other devices can reach it (`npm run dev -- -H 0.0.0.0` in `../web`) and
   find its Wi-Fi IP (macOS: System Settings → Wi-Fi → Details → IP address).
3. With the phone on the same Wi-Fi, open the app → **Account → Server address**, enter e.g.
   `http://192.168.1.20:3000`, and tap **Test & save**. If the app can't reach a server, the error screen also
   links to this setting.

The APK is built by `.github/workflows/android-release.yml` on every push to `main` and replaces the asset on the
rolling `latest-android` release. Without signing secrets it uses a throwaway debug key, so each new build must be
installed after uninstalling the old one. For in-place updates, add repository secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` (the workflow writes
`android/key.properties`, which is git-ignored). Release builds allow plain `http://` so LAN testing works.

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
