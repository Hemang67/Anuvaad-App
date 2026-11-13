#!/usr/bin/env bash
# Fails unless a built APK has the permissions a release needs and the expected versionCode.
# Usage: tool/release/check_apk.sh <path-to-aapt2> <apk> <expected-version-code>
set -euo pipefail
aapt2=$1
apk=$2
expected=$3
perms=$("$aapt2" dump permissions "$apk")
badging=$("$aapt2" dump badging "$apk")
fail=0
for permission in android.permission.INTERNET android.permission.REQUEST_INSTALL_PACKAGES android.permission.RECORD_AUDIO \n  android.permission.FOREGROUND_SERVICE_MICROPHONE android.permission.POST_NOTIFICATIONS; do
  if ! grep -q "uses-permission: name='$permission'" <<<"$perms"; then
    echo "::error::$apk is missing $permission"
    fail=1
  fi
done
code=$(grep -o "versionCode='[0-9]*'" <<<"$badging" | grep -o '[0-9]*')
if [ "$code" != "$expected" ]; then
  echo "::error::$apk has versionCode $code, expected $expected"
  fail=1
fi
[ "$fail" = 0 ] && echo "OK: $apk (versionCode $code, permissions present)"
exit "$fail"
