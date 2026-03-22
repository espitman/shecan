#!/bin/sh
set -euo pipefail

HELPER_LABEL="ir.shecan.desktop.helper"
HELPER_OUTPUT_DIR="${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}/Contents/Library/LaunchServices"
HELPER_BINARY="${HELPER_OUTPUT_DIR}/${HELPER_LABEL}"
INFO_PLIST="${SRCROOT}/Sources/Resources/Helper/Helper-Info.plist"
LAUNCHD_PLIST="${SRCROOT}/Sources/Resources/Helper/Helper-Launchd.plist"
SHARED_SOURCE="${SRCROOT}/Sources/Shared/XPC/PrivilegedHelperProtocol.swift"
HELPER_MAIN="${SRCROOT}/Sources/Helper/Sources/HelperMain.swift"
HELPER_SERVICE="${SRCROOT}/Sources/Helper/Sources/PrivilegedHelperService.swift"

mkdir -p "${HELPER_OUTPUT_DIR}"

if [ -n "${ARCHS:-}" ]; then
  HELPER_ARCH="$(printf '%s' "${ARCHS}" | awk '{print $1}')"
else
  HELPER_ARCH="${NATIVE_ARCH_ACTUAL}"
fi

xcrun swiftc \
  -target "${HELPER_ARCH}-apple-macos${MACOSX_DEPLOYMENT_TARGET}" \
  -O \
  "${SHARED_SOURCE}" \
  "${HELPER_MAIN}" \
  "${HELPER_SERVICE}" \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "${INFO_PLIST}" \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __launchd_plist \
  -Xlinker "${LAUNCHD_PLIST}" \
  -o "${HELPER_BINARY}"

codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" --timestamp=none "${HELPER_BINARY}"
