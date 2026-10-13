#!/bin/zsh
# Build the app, launch one design screen in a simulator, and save a screenshot.
# Usage: scripts/screenshot.sh <simulator-udid> <derived-data-dir> <screen-id> <out.png> [--no-build] [app args...]
# Example: scripts/screenshot.sh $SIM /tmp/dd S06 /tmp/S06.png -ja
# Use an iPhone 16e simulator: it is 390×844 pt, the design's frame size.
set -e
sim=$1 dd=$2 screen=$3 out=$4; shift 4
here=${0:a:h}/..
build=1; [[ "$1" == "--no-build" ]] && { build=0; shift; }
xcrun simctl boot "$sim" 2>/dev/null || true
# The design's status bar (F02): 9:41, full signal, Wi-Fi, battery about 75%.
xcrun simctl status_bar "$sim" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 75 2>/dev/null || true
if (( build )); then
  xcodebuild -project "$here/FreedomIOSApp.xcodeproj" -scheme AhhPuck -destination "platform=iOS Simulator,id=$sim" \
    -derivedDataPath "$dd" build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -30
  xcrun simctl install "$sim" "$dd/Build/Products/Debug-iphonesimulator/AhhPuck.app"
fi
xcrun simctl terminate "$sim" com.ahhpuck.freedom 2>/dev/null || true
xcrun simctl launch "$sim" com.ahhpuck.freedom -screen "$screen" -demoClock "$@" >/dev/null
sleep 3
xcrun simctl io "$sim" screenshot "$out" >/dev/null 2>&1
echo "$out"
