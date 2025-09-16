# Repository Guidelines
日本語で簡潔かつ丁寧に回答してください

## Project Structure & Module Organization
The Flutter app lives in `lib/`, split by layer: `presentation/` for UI widgets and routing, `domain/` for models and use-cases, `infrastructure/` for data sources, and `common/` utilities (logging, shared services, asset helpers). Runtime configuration is centralized in `lib/app_config.dart` and `lib/config/`. Platform shells remain in `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and the web entry in `web/`. Shared images and JSON live under `assets/`. Tests belong in `test/`, mirroring `lib/` packages for future suites.

## Build, Test & Development Commands
- `flutter pub get` syncs dependencies after editing `pubspec.yaml`.
- `flutter analyze` enforces the `analysis_options.yaml` lint set; run before every PR.
- `bash command/deveice_running.sh` starts the dev app with `FLAVOR=development` and disables sound null safety for legacy packages.
- `bash command/build_runner.sh` regenerates generated sources (e.g., JSON serializers); rerun after editing annotations.
- `flutter test` executes unit and widget tests; add `--coverage` when validating coverage locally.
- `bash command/android_release.sh` produces the Play-ready app bundle; update the version in `pubspec.yaml` first.

## Coding Style & Naming Conventions
Adhere to Dart's standard two-space indentation and favor trailing commas to keep diffs formatter-friendly; always run `dart format lib test`. Keep filenames snake_case (`user_profile_page.dart`) and classes in PascalCase. Use lowerCamelCase for members and top-level consts. Prefer immutable data classes and `const` constructors where practical. Avoid direct `print`; rely on helpers in `lib/common/logger.dart`. Document feature APIs with concise DartDoc when exposing them outside the module.

## Testing Guidelines
Place tests in `test/` mirroring the `lib/` path (`lib/presentation/home/...` → `test/presentation/home/...`). Name files with the `_test.dart` suffix and describe the behavior under test. Start new suites by copying the existing `widget_test.dart` structure. Favor the `flutter_test` framework for widget coverage and `package:test` for pure Dart logic. Validate major services with mock-friendly abstractions under `lib/common/services/`. Ensure new features include happy-path and failure coverage before requesting review.

## Commit & Pull Request Guidelines
Commits in this repo favor short, imperative summaries (`Fix loading indicator`, `Implement ad frequency control`) along with occasional release tags (`android-release`). Follow the same style, keeping scope focused in each commit and referencing tickets where relevant (`refs #123`). Before opening a PR, sync with `main`, run analysis/tests, and attach screenshots or recordings for UI updates. PR descriptions should outline the change set, testing performed, and follow-up work. Link related issues and flag migration steps for QA.
