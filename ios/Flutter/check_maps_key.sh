#!/bin/sh
set -eu

# Google Maps raises an Objective-C exception when a map is created without
# provideAPIKey. Stop every Xcode/Flutter build before producing such a binary.
case "${GOOGLE_MAPS_API_KEY:-}" in
  ''|*'$('*|YOUR_*)
    echo 'error: GOOGLE_MAPS_API_KEY is missing. Restore ios/Flutter/MapsKeys.xcconfig before building. Never print or commit its value.' >&2
    exit 1
    ;;
esac
