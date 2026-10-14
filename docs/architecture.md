# Architecture

## Stack

| Layer | Choice | Why |
|---|---|---|
| App | Flutter + Dart | One codebase for iOS and Android |
| State | Riverpod (`Notifier`, `FutureProvider`) | Testable, no BuildContext needed |
| GPS | `geolocator` | Free; background tracking via iOS background mode / Android foreground service |
| Map | `flutter_map` + OpenStreetMap tiles | No API key or billing |
| Offline store | `sqflite` | Points saved as they arrive; no code generation step |
| Backend | Supabase (Auth, Postgres + RLS, Edge Functions) | Free tier covers several classes |

## App layers

```
Screens  ──>  View models (Riverpod Notifiers)  ──>  Repositories  ──>  LocalDb / ApiClient
                         │
                         └──> LocationTracker ──> GpsFilter
```

- `ApiClient` is the only class that imports Supabase. Replace it to change backends.
- `RunRepository` is offline-first: write locally, `syncPending()` later.

## Data model

`School 1─* Profile(role)`, `Profile(teacher) 1─* ClassGroup *─* Profile(student)` via `class_members`,
`ClassGroup 1─* Assignment 1─* Run`, `Run 1─* GpsPoint`, `Run 1─1 RunValidation`.

## Security

Row level security on every table:
- Students read/write only their own runs and points, and see classes they joined.
- Teachers see their own classes, and the runs and profiles of students in those classes.
- `run_validations` and run status are written only by the `validate-run` function (service role).

## Privacy

Students are likely minors and GPS routes reveal where they live. Before rollout:
get school/parent consent, keep only what grading needs (consider deleting `gps_points`
after a term), and check Vietnam's personal data rules (Decree 13/2023/NĐ-CP).
