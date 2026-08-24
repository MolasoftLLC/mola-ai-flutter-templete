#!/bin/bash

set -euo pipefail

# CocoaPodsはUTF-8ロケールを必要とする。
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 署名せずにiOS Releaseビルドの成立を確認する。
flutter build ios --release --no-codesign "$@"
