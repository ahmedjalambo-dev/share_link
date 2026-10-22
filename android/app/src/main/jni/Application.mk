APP_OPTIM := release
APP_PLATFORM := android-24
# PKGNAME tells hev-jni.c which Java class gets the native methods:
# com.example.share_link.TProxyService
APP_CFLAGS := -O3 -DPKGNAME=com/example/share_link
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true
NDK_TOOLCHAIN_VERSION := clang
