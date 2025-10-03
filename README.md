# Asset Management Mobile

Flutter client for the Geumcheon asset-management stack. The app talks to the Laravel backend to manage company assets, capture photos, and keep audit trails for assignments and requests.

## Highlights

- ?? Flutter 3 UI with Bloc state management and responsive layouts.
- ?? Sanctum-authenticated API integration with persistent sessions.
- ??? Asset CRUD, category filters, search, and status breakdowns.
- ?? Assignment workflow with department-aware user list.
- ??? Capture or pick asset photos and upload them to the backend.

## Tech Stack

| Layer | Tools |
| --- | --- |
| Mobile | Flutter, flutter_bloc, image_picker |
| Backend | Laravel 11, Sanctum, MySQL |
| Auth | Token-based (Bearer) |

## Prerequisites

- Flutter SDK 3.19+
- Dart 3.3+
- Android Studio or Xcode (for device builds)
- PHP 8.2+, Composer
- MySQL 8+

## Backend Setup

1. cd laravel_geumcheon
2. Copy .env.example to .env and adjust DB credentials.
3. composer install
4. php artisan key:generate
5. php artisan migrate --seed
6. Ensure the storage symlink exists (php artisan storage:link).
7. Serve the API: php artisan serve --host=0.0.0.0

### Image Upload Notes

- Asset photos are stored on the public disk under sset-photos/.
- API returns both sset_photo_path and sset_photo_url.
- Updating an asset with the emove_asset_photo flag set removes the existing file.

## Mobile App Setup

1. cd snipe_it
2. lutter pub get
3. Update lib/core/config/api_config.dart with the reachable backend base URL.
4. For Android 13+, ensure the app has READ_MEDIA_IMAGES permission (already included).
5. For iOS, Info.plist contains NSPhotoLibraryUsageDescription.
6. Run the app: lutter run

### Common Issues

- MissingPluginException (image_picker): stop the running build and rerun lutter run after adding the plugin.
- HTTP 500 errors on dashboard: check storage/logs/laravel.log (DB connection or schema mismatches are typical culprits).
- 401/403 responses: confirm the app logged in via /api/auth/login and the bearer token is stored.

## Environment Variables

| Key | Description |
| --- | --- |
| API_BASE_URL (Flutter) | Configured in ApiConfig.baseUrl |
| .env APP_URL (Laravel) | Used to generate absolute image URLs |
| .env SANCTUM_STATEFUL_DOMAINS | Required if hosting on multiple domains |

## Project Structure (Flutter)

`
lib/
  core/
  data/
  domain/
  presentation/
    bloc/
    screens/
    widgets/
`

- presentation/screens/add_asset/add_asset_screen.dart: asset form with photo picker.
- data/repositories/asset_repository.dart: orchestrates API calls and multipart uploads.
- presentation/bloc/asset/asset_cubit.dart: state management for dashboard and CRUD.

## Backend Endpoints Consumed

- POST /api/auth/login
- GET /api/dashboard
- GET /api/assets
- POST /api/assets
- PUT /api/assets/{id}
- DELETE /api/assets/{id}
- GET /api/users

## License

This project is proprietary to Geumcheon internal tooling. Contact the maintainers for access or redistribution requests.
