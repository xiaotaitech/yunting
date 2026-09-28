#!/usr/bin/env bash
# 启动本地 Android 模拟器并把 App 跑起来。
#
#   ./run-emulator.sh demo                  演示模式：不需要 AppKey，直接试完整流程
#   ./run-emulator.sh <AppKey> <代理地址>    连真实百度网盘
#   ./run-emulator.sh                       什么都不传，停在配置引导页
#
# 模拟器里访问宿主机上的 OAuth 代理要用 10.0.2.2（模拟器对宿主的固定别名），
# 不是 127.0.0.1 —— 后者指向模拟器自己。
set -euo pipefail

cd "$(dirname "$0")"
source ./env.sh

AVD_NAME="yun_test"
SYSTEM_IMAGE="system-images;android-35;google_apis;x86_64"

# --- 没有 AVD 就建一个
if ! "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat" list avd 2>/dev/null \
     | grep -q "Name: $AVD_NAME"; then
  echo "创建 AVD：$AVD_NAME"
  echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat" create avd \
    --name "$AVD_NAME" --package "$SYSTEM_IMAGE" --device "pixel_5" --force
fi

# --- 起模拟器（已经在跑就跳过）
if ! adb devices | grep -q "emulator-.*device"; then
  echo "启动模拟器…"
  "$ANDROID_HOME/emulator/emulator.exe" -avd "$AVD_NAME" -no-snapshot-load -no-boot-anim &
  echo "等待开机完成…"
  adb wait-for-device
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 3
  done
fi
echo "模拟器就绪：$(adb devices | grep emulator | head -1)"

# --- 跑 App
APP_KEY="${1:-}"
PROXY="${2:-}"

cd app
if [[ "$APP_KEY" == "demo" ]]; then
  echo
  echo "演示模式：数据源是本地假网盘，音频是现场生成的。"
  echo "书架、章节排序、播放、进度、倍速、定时都是真的在跑。"
  echo
  flutter run -d emulator-5554 --dart-define=DEMO_MODE=true
elif [[ -n "$APP_KEY" && -n "$PROXY" ]]; then
  flutter run -d emulator-5554 \
    --dart-define=BAIDU_APP_KEY="$APP_KEY" \
    --dart-define=OAUTH_PROXY_BASE="$PROXY"
else
  echo
  echo "没传参数，App 会停在「需要先完成配置」引导页。"
  echo "  想先试试：      ./run-emulator.sh demo"
  echo "  连真实网盘：    ./run-emulator.sh <AppKey> http://10.0.2.2:8787"
  echo
  flutter run -d emulator-5554
fi
