# Runner

A Strava-style run tracker for PE classes. Students record runs with GPS; teachers create classes and assignments (e.g. "1 km test"), see a leaderboard, and review flagged runs.

```
runner-app/
├── app/                 Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── core/        config + Riverpod providers
│   │   ├── models/      User, ClassGroup, Assignment, Run, GpsPoint
│   │   ├── tracking/    LocationTracker, GpsFilter, RunCalculator
│   │   ├── data/        ApiClient (Supabase), LocalDb (SQLite), repositories
│   │   └── features/    auth, run, history, teacher screens + view models
│   └── test/
├── supabase/
│   ├── migrations/      Postgres schema, RLS policies, join_class + leaderboard functions
│   └── functions/validate-run/   server-side anti-cheat check
└── docs/architecture.md
```

## 1. Install tools (macOS)

```bash
brew install --cask flutter
brew install supabase/tap/supabase
# iOS builds also need Xcode from the App Store, then:
sudo xcodebuild -runFirstLaunch && brew install cocoapods
flutter doctor
```

## 2. Generate the iOS/Android folders

The repo holds the Dart code only. Generate the native shells once (existing `lib/` is kept):

```bash
cd app
flutter create . --org vn.edu.runner --platforms=ios,android --project-name runner_app
flutter pub get
flutter test
```

Commit the generated `ios/` and `android/` folders afterwards.

## 3. Platform permissions for background GPS

**iOS** — add to `app/ios/Runner/Info.plist` inside `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Runner records your route while you run for PE class.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Runner keeps recording your run when the screen is locked.</string>
<key>UIBackgroundModes</key>
<array><string>location</string></array>
```

**Android** — add to `app/android/app/src/main/AndroidManifest.xml` above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

## 4. Backend (Supabase)

1. Create a free project at supabase.com.
2. Link and push the schema, deploy the function:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase db push
   supabase functions deploy validate-run
   ```
3. Create a teacher account: Authentication → Add user, with user metadata `{"name": "Thầy A", "role": "teacher"}`. Students who sign up default to `student`.

## 5. Run the app

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Test GPS tracking on a real phone outdoors — simulators only replay fake routes.

## How a run flows

1. `RunViewModel.start()` → `LocationTracker` streams GPS → `GpsFilter` drops inaccurate points and impossible jumps (> 7 m/s).
2. Each point is written to on-device SQLite as it arrives, so nothing is lost if the app is killed or offline.
3. On finish, `RunRepository.syncPending()` uploads the run + points, then calls the `validate-run` edge function.
4. `validate-run` marks the run `approved` or `flagged` (too many fast segments, GPS gaps > 60 s, too few points). Pausing a run creates a gap, so teachers should glance at flagged runs rather than treat them as cheating.

## Not built yet

- Student "join class" screen (backend `join_class(code)` RPC is ready; `ApiClient.joinClass` calls it)
- Excel export, push notifications, run detail map for teachers
- Sign-up screen (accounts currently created by the teacher/admin)
