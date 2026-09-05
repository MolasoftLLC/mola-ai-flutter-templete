#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

release_version="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
if [[ ! "${release_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "pubspec.yaml の version が不正です: ${release_version}" >&2
  exit 1
fi

if [[ ! -f android/key.properties ]]; then
  echo "Android署名設定が見つかりません: android/key.properties" >&2
  exit 1
fi

if [[ ! -f android/app/google-services.json ]]; then
  echo "Firebase設定が見つかりません: android/app/google-services.json" >&2
  exit 1
fi

echo "Android ${release_version} の署名付きAABを作成します。"
flutter pub get
flutter build appbundle \
  --release \
  --dart-define=FLAVOR=production

aab_path="build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "${aab_path}" ]]; then
  echo "AABが見つかりません: ${aab_path}" >&2
  exit 1
fi

echo "Android App Bundleを作成しました: ${aab_path}"
