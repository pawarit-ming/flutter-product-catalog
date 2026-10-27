# Product Catalog (Flutter)

A two-screen Flutter app — **Product List** and **Product Detail** — backed by the
real [Platzi Fake Store API](https://fakeapi.platzi.com/). State is managed with
**Riverpod**, HTTP is done with **Dio**, and the layout adapts to phones and
tablets.

| Mobile — list | Mobile — detail | Tablet — list | Tablet — detail (landscape) |
|---|---|---|---|
| ![](docs/screenshots/mobile-list.png) | ![](docs/screenshots/mobile-detail.png) | ![](docs/screenshots/tablet-list.png) | ![](docs/screenshots/tablet-detail.png) |

## Requirements checklist

| # | Requirement | Where |
|---|---|---|
| 1 | List shows image, name, price | `presentation/widgets/product_card.dart` |
| 2 | Tap opens product detail | `ProductListScreen._openProduct` → `ProductDetailScreen(productId)` |
| 3 | Riverpod | `productListProvider` (AsyncNotifier), `productDetailProvider` (FutureProvider.family), `dioProvider`, `productRepositoryProvider` |
| 4 | Dio | `data/product_repository.dart` (`DioProductRepository`) |
| 5 | Loading / Error / Empty | Initial load, Load More, Refresh and Detail each have their own states |
| 6 | Pull-to-refresh | `RefreshIndicator` + `AlwaysScrollableScrollPhysics` (works on empty and error states too) |
| 7 | Pagination / Load More | "Load more" button with spinner and Retry at the end of the grid |
| 8 | Mobile and tablet | Column count from real width (1–4), content max 1200 dp, two-pane detail from 840 dp |
| 9 | UI / State / Repository split | `presentation/` / `application/` / `data/` |
| 10 | No hardcoded products | All products come from the API; fake data exists only under `test/` |

## Versions

| Tool | Version |
|---|---|
| Flutter | 3.38.7 (stable) |
| Dart | 3.10.7 |
| flutter_riverpod / riverpod | 3.3.2 |
| dio | 5.11.1 |
| intl | 0.20.3 |

Exact dependency versions are pinned in `pubspec.lock`.

## Getting started

```bash
flutter pub get
flutter run            # pick an Android device or emulator
```

Run the checks:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release   # output: build/app/outputs/flutter-apk/app-release.apk
```

Tests use a fake repository and a fake Dio adapter, so they need no internet.

## Architecture

```
lib/
  main.dart                     ProviderScope (automatic retry disabled)
  app.dart                      MaterialApp, Material 3 theme
  core/
    errors/app_exception.dart   error types + user-facing messages
    network/dio_provider.dart   shared Dio (10 s connect / 15 s receive timeout)
    riverpod/no_retry.dart      disables Riverpod 3 automatic retry
    formatting/price_format.dart
  features/products/
    data/                       Product, ProductCategory, ProductPage, ProductRepository
    application/                ProductListState, ProductListNotifier, productDetailProvider
    presentation/               ProductListScreen, ProductDetailScreen, widgets/
```

Flow: **UI → Riverpod providers → ProductRepository → Dio → REST API**

- **UI** only renders state and forwards user actions; it never touches Dio.
- **State** (`ProductListNotifier`) owns the list, the cursor and the Load More /
  Refresh flags.
- **Repository** calls the API, validates JSON and turns every failure into an
  `AppException` (`timeout`, `network`, `notFound`, `server`, `invalidData`,
  `cancelled`). Users never see raw exceptions or stack traces.
- Dio and the repository are provided through Riverpod, so tests replace them
  with `overrideWithValue`.

### Data validation

- `id` (int), `title` (non-empty string) and `price` (non-negative number) are
  required. If any is missing or has the wrong type, the **whole response is
  rejected** with an "unexpected data" error. Products are never silently
  skipped, and no price is replaced with 0.
- Optional fields fall back: description → "No description available",
  category → "Uncategorized", images → placeholder.
- Images are filtered to absolute `http`/`https` URLs. Some API records wrap
  URLs in stray `["…"]`, which are trimmed off. Failed images show a placeholder.
- For an unknown product ID the live API returns **HTTP 400** with
  `"name": "EntityNotFoundError"`, not 404. Both are mapped to "Product not found".

## Pagination and refresh

The API takes `offset` / `limit` and returns a plain JSON array with no total.

1. Page size is 20, starting at offset 0.
2. `nextOffset = requestOffset + rawItemCount`, counted **before**
   de-duplication. A duplicate ID therefore never shifts the cursor.
3. `hasMore` is false once a page returns fewer than 20 items (an empty page
   included). If the last page is exactly 20 items, the next request returns
   an empty page and ends pagination.
4. Load More is ignored while a Load More or a Refresh is running. On failure
   the cursor does not move, so Retry asks for the same offset again.
5. Items are appended only if their ID is not already in the list.

**Refresh while Load More is running.** Each refresh increments a
*generation* counter and cancels the in-flight Load More via its `CancelToken`.
Every request records the generation it started with. Its success, error and
cleanup paths only write state if that generation is still current and the
provider is still mounted (`ref.mounted`). A slow old request therefore can't
add stale items, move the cursor, or switch off the new request's spinner.

**Refresh semantics.**
- The current items stay on screen while refreshing.
- On success the first page replaces the list and the cursor is reset.
- On failure the old items, cursor and `hasMore` are kept. A SnackBar shows
  once for that request, and Load More continues from the old cursor.
- Concurrent refresh calls share the same Future, and that Future always
  completes, so the `RefreshIndicator` never spins forever.

**Lifecycle.**
- `productListProvider` lives at the root scope and is not auto-disposed.
  Opening a product and coming back keeps the loaded items and the scroll
  position (one `ScrollController` plus a `PageStorageKey`), with no reload.
- `productDetailProvider` is `autoDispose.family` by ID. Leaving the screen
  cancels only that request, never the shared Dio client.
- Riverpod 3's automatic retry is turned off. Failures show an explicit Retry
  button instead of retrying silently in the background.
- Initial-load Retry invalidates the list provider. Detail Retry invalidates
  only that product. Load More Retry calls `loadMore()` with the same cursor.

## Responsive layout

| Available width | Behaviour |
|---|---|
| Any | 16 dp side padding, 12 dp gaps, cards ≥ 150 dp wide, 1–4 columns computed from the real width (`LayoutBuilder`) |
| > 1200 dp | Content centred and capped at 1200 dp |
| Detail < 840 dp | Image above the details |
| Detail ≥ 840 dp | Image and details side by side |

Card height is calculated from the current text scale, so titles (max 2 lines,
ellipsis) and prices are never clipped. Widget tests check for overflow at
360×800, 800×1280 and 1280×800 with text scale 1.0 and 1.5.

## Testing

`flutter test` runs 62 tests:

- **Model**: int/decimal prices, optional-field defaults, image URL filtering,
  rejection of bad id/title/price.
- **Repository** (fake Dio adapter): query parameters, cursor and `hasMore`,
  malformed responses, 404 / 400 EntityNotFound / 500 mapping, timeout,
  network, invalid JSON, cancellation.
- **State**: first page, empty result, append with duplicates, end of
  pagination (short page and exact-limit page followed by an empty page),
  duplicate Load More guard, Load More retry at the same offset, refresh
  success and failure, shared concurrent refresh, Load More blocked during
  refresh, stale Load More finishing late (success and failure) after a
  refresh, and resuming from the old cursor after a failed refresh.
- **Widgets**: loading / error / empty, Retry, pull-to-refresh on error and
  empty states, refresh error shown once, Load More spinner and Retry, opening
  the right product ID, returning with the same scroll position and no reload,
  detail Retry, "Product not found" with Back, and the overflow matrix above.

### Tested on

- **Android emulator** (Pixel 8, Android 16 / API 36) with the **release APK**:
  loaded real products and images, Load More, Detail → Back, plus tablet
  sizes 800×1280 dp and 1280×800 dp (set with `adb shell wm size/density`).
- **Not tested**: iOS (no macOS/Xcode available), physical Android devices,
  turning the network off on the emulator mid-request (covered by unit and
  widget tests with fake failures).

## Assumptions and limitations

- **Currency**: the API has no currency field, so prices are shown as USD with
  two decimals (`$44.00`). No conversion is done.
- The API is a public test service: its data and IDs can change at any time,
  so nothing in the app depends on specific IDs or product counts. Offset
  paging may skip or repeat items if the data changes between requests.
  Duplicates are removed, and Refresh reloads from the start.
- UI text is in English; product content is shown as the API returns it.
- No image cache package is used (`Image.network` only).
- Login, cart, search, filters, favourites and offline cache are out of scope.

## Possible improvements

- Infinite scroll (auto Load More near the end) alongside the button
- Image gallery on the detail page, plus an image cache package
- Search and category filters (the API supports `title` and `categoryId`)
- Offline cache of the last loaded page
- Integration tests on a device (`integration_test`) and CI
