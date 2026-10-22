#!/usr/bin/env bash
# Rebuilds libhev-socks5-tunnel.so (tun2socks for client mode) into ../jniLibs/<abi>/.
# Run from Git Bash after updating jni/hev-socks5-tunnel:
#   android/app/src/main/jni/build-tun2socks.sh
#
# Note for Windows: the library's git repos contain symlinked headers. Clone with
# `git -c core.symlinks=true clone --recursive ...` (needs Developer Mode), or replace each
# symlink placeholder file with a copy of its target before building.
set -euo pipefail

JNI_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_DIR="${ANDROID_HOME:-$LOCALAPPDATA/Android/Sdk}"
NDK_DIR="${ANDROID_NDK_HOME:-$SDK_DIR/ndk/28.2.13676358}"
OUT_DIR="$(mktemp -d)"
NDK_BUILD="$NDK_DIR/ndk-build"
[ -f "$NDK_BUILD.cmd" ] && NDK_BUILD="$NDK_BUILD.cmd"

"$NDK_BUILD" \
    NDK_PROJECT_PATH="$OUT_DIR" \
    APP_BUILD_SCRIPT="$JNI_DIR/Android.mk" \
    NDK_APPLICATION_MK="$JNI_DIR/Application.mk" \
    APP_ABI="arm64-v8a armeabi-v7a x86_64" \
    NDK_OUT="$OUT_DIR/obj" \
    NDK_LIBS_OUT="$OUT_DIR/libs" \
    -j8

for abi in arm64-v8a armeabi-v7a x86_64; do
    mkdir -p "$JNI_DIR/../jniLibs/$abi"
    cp "$OUT_DIR/libs/$abi/libhev-socks5-tunnel.so" "$JNI_DIR/../jniLibs/$abi/"
done
echo "Copied libhev-socks5-tunnel.so into $JNI_DIR/../jniLibs"
