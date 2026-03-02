# App Icon Assets

Place your app icon files here before running the icon generator.

Required files:
- `icon.png` — 1024x1024 px, full app icon (used for iOS and as Android legacy icon)
- `icon_foreground.png` — 1024x1024 px, foreground layer for Android adaptive icon (should have transparent background with ~66% safe zone)

Background color for adaptive icon: `#0A0A1A` (configured in pubspec.yaml)

Once the icon files are ready, run:
```
flutter pub run flutter_launcher_icons
```
