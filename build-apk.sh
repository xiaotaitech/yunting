#!/usr/bin/env bash
# 带凭证打 release APK。
#
#   ./build-apk.sh <AppKey> <OAuth代理地址>
#   ./build-apk.sh abc123 http://192.168.1.10:8787
#
# 不带参数构建出来的包也能装能开，但会停在「需要先完成配置」引导页。
set -euo pipefail

cd "$(dirname "$0")"
source ./env.sh

APP_KEY="${1:-}"
PROXY="${2:-}"

if [[ -z "$APP_KEY" || -z "$PROXY" ]]; then
  echo "用法：./build-apk.sh <AppKey> <OAuth代理地址>"
  echo "例如：./build-apk.sh abc123xyz http://192.168.1.10:8787"
  echo
  echo "AppKey 到 https://pan.baidu.com/union/console 申请（需实名认证）。"
  exit 1
fi

cd app
flutter build apk --release \
  --dart-define=BAIDU_APP_KEY="$APP_KEY" \
  --dart-define=OAUTH_PROXY_BASE="$PROXY"

echo
echo "产物：app/build/app/outputs/flutter-apk/app-release.apk"
echo "安装：adb install -r app/build/app/outputs/flutter-apk/app-release.apk"
