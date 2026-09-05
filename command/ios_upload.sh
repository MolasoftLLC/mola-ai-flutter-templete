#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

for required_command in flutter pod xcodebuild plutil; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    echo "必要なコマンドが見つかりません: ${required_command}" >&2
    exit 1
  fi
done

release_version="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
if [[ ! "${release_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "pubspec.yaml の version が不正です: ${release_version}" >&2
  exit 1
fi

version_name="${release_version%%+*}"
build_number="${release_version##*+}"
team_id="$(awk '/DEVELOPMENT_TEAM =/ {value=$3; sub(/;/, "", value); print value; exit}' ios/Runner.xcodeproj/project.pbxproj)"

if [[ -z "${team_id}" ]]; then
  echo "XcodeプロジェクトからDEVELOPMENT_TEAMを取得できませんでした。" >&2
  exit 1
fi

echo "iOS ${version_name} (${build_number}) をApp Store Connectへアップロードします。"
if [[ "${RELEASE_CONFIRM:-0}" != "1" ]]; then
  read -r -p "続行しますか？ [y/N]: " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    echo "中止しました。"
    exit 0
  fi
fi

flutter pub get
(
  cd ios
  pod install
)

flutter build ipa \
  --release \
  --dart-define=FLAVOR=production

archive_path="build/ios/archive/Runner.xcarchive"
app_info="${archive_path}/Products/Applications/Runner.app/Info.plist"

if [[ ! -f "${app_info}" ]]; then
  echo "iOSアーカイブが見つかりません: ${archive_path}" >&2
  exit 1
fi

archive_version="$(plutil -extract CFBundleShortVersionString raw "${app_info}")"
archive_build="$(plutil -extract CFBundleVersion raw "${app_info}")"
if [[ "${archive_version}" != "${version_name}" || "${archive_build}" != "${build_number}" ]]; then
  echo "アーカイブのバージョンが一致しません: ${archive_version} (${archive_build})" >&2
  exit 1
fi

upload_dir="$(mktemp -d "${TMPDIR:-/tmp}/sakepedia-ios-upload.XXXXXX")"
cleanup() {
  case "${upload_dir}" in
    "${TMPDIR:-/tmp}"/sakepedia-ios-upload.*) rm -rf "${upload_dir}" ;;
  esac
}
trap cleanup EXIT

export_options="${upload_dir}/ExportOptions.plist"
cat >"${export_options}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>upload</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${team_id}</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "${export_options}"
xcodebuild \
  -exportArchive \
  -archivePath "${archive_path}" \
  -exportPath "${upload_dir}/export" \
  -exportOptionsPlist "${export_options}" \
  -allowProvisioningUpdates

echo "App Store Connectへのアップロードが完了しました: ${version_name} (${build_number})"
