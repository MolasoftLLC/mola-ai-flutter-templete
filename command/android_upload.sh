#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

# This file is local-only (*.env is ignored). Explicit environment values win.
if [[ -z "${PLAY_STORE_SERVICE_ACCOUNT_JSON:-}" && -f "${SCRIPT_DIR}/android_upload.local.env" ]]; then
  source "${SCRIPT_DIR}/android_upload.local.env"
fi

json_key="${PLAY_STORE_SERVICE_ACCOUNT_JSON:-}"
track="${PLAY_TRACK:-internal}"
release_status="${PLAY_RELEASE_STATUS:-draft}"
package_name="okinawa.molasoft_ai.sake"

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--check" ) ]]; then
  echo "使い方: bash command/android_upload.sh [--check]" >&2
  exit 1
fi

if [[ -z "${json_key}" || ! -f "${json_key}" ]]; then
  echo "Google PlayサービスアカウントJSONを指定してください。" >&2
  echo "例: PLAY_STORE_SERVICE_ACCOUNT_JSON=/安全な場所/key.json bash command/android_upload.sh" >&2
  exit 1
fi

if command -v fastlane >/dev/null 2>&1; then
  fastlane_command=(fastlane)
elif [[ -f Gemfile ]] && command -v bundle >/dev/null 2>&1; then
  fastlane_command=(bundle exec fastlane)
else
  echo "fastlaneが見つかりません。先にfastlaneをインストールしてください。" >&2
  exit 1
fi

export FASTLANE_OPT_OUT_USAGE=1
export FASTLANE_SKIP_UPDATE_CHECK=1

if [[ "${1:-}" == "--check" ]]; then
  "${fastlane_command[@]}" run validate_play_store_json_key json_key:"${json_key}"
  "${fastlane_command[@]}" run google_play_track_version_codes \
    json_key:"${json_key}" package_name:"${package_name}" track:"${track}"
  echo "Google Playへの接続確認が完了しました（ビルド・アップロードなし）。"
  exit 0
fi

bash command/android_release.sh
aab_path="build/app/outputs/bundle/release/app-release.aab"
release_version="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"

echo "Android ${release_version} をGoogle Playの ${track} トラックへ ${release_status} でアップロードします。"
if [[ "${RELEASE_CONFIRM:-0}" != "1" ]]; then
  read -r -p "続行しますか？ [y/N]: " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    echo "中止しました。"
    exit 0
  fi
fi

"${fastlane_command[@]}" supply \
  --aab "${aab_path}" \
  --json_key "${json_key}" \
  --package_name "${package_name}" \
  --track "${track}" \
  --release_status "${release_status}" \
  --skip_upload_metadata true \
  --skip_upload_images true \
  --skip_upload_screenshots true

echo "Google Playへのアップロードが完了しました: ${release_version}"
