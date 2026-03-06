#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PATCH_DIR="${SCRIPT_DIR}/patches"
PATCH_FILE="${PATCH_DIR}/0001-nejikure-nejimaki.patch"

BCDICE_JS_REPO="${BCDICE_JS_REPO:-https://github.com/bcdice/bcdice-js.git}"
BCDICE_JS_REF="${BCDICE_JS_REF:-v4.9.0}"
CUSTOM_SUFFIX="${CUSTOM_SUFFIX:-nejikure.0}"
BUNDLER_VERSION="${BUNDLER_VERSION:-2.6.3}"
WORK_DIR="${WORK_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/bcdice-custom.XXXXXX")}"
KEEP_WORK_DIR="${KEEP_WORK_DIR:-0}"

VENDOR_DIR="${ROOT_DIR}/vendor/bcdice"
ARCHIVE_DIR="${VENDOR_DIR}/archive"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "[ERROR] patch file not found: ${PATCH_FILE}" >&2
  exit 1
fi

cleanup() {
  if [[ "${KEEP_WORK_DIR}" == "1" ]]; then
    echo "[INFO] KEEP_WORK_DIR=1 のため作業ディレクトリを保持: ${WORK_DIR}"
  else
    rm -rf "${WORK_DIR}"
  fi
}
trap cleanup EXIT

mkdir -p "${ARCHIVE_DIR}"

echo "[INFO] work dir: ${WORK_DIR}"
echo "[INFO] clone bcdice-js: ${BCDICE_JS_REPO} @ ${BCDICE_JS_REF}"
git clone --depth 1 --branch "${BCDICE_JS_REF}" "${BCDICE_JS_REPO}" "${WORK_DIR}/bcdice-js"

cd "${WORK_DIR}/bcdice-js"

echo "[INFO] init submodule"
git submodule update --init --recursive

echo "[INFO] apply patch: ${PATCH_FILE}"
git -C BCDice apply "${PATCH_FILE}"

echo "[INFO] bcdice-js commit: $(git rev-parse HEAD)"
echo "[INFO] BCDice commit(after patch): $(git -C BCDice rev-parse HEAD)"

echo "[INFO] install npm dependencies"
npm ci

echo "[INFO] install ruby dependencies"
export BUNDLE_WITH=development:test
export BUNDLE_WITHOUT=
export BUNDLER_VERSION

if bundle "_${BUNDLER_VERSION}_" --version >/dev/null 2>&1; then
  BUNDLE_CMD=(bundle "_${BUNDLER_VERSION}_")
else
  echo "[WARN] bundler ${BUNDLER_VERSION} が見つからないため system bundler を使用"
  BUNDLE_CMD=(bundle)
fi

"${BUNDLE_CMD[@]}" config unset without || true
"${BUNDLE_CMD[@]}" install

echo "[INFO] clean/build/test"
npm run clean
npm run build
npm test

echo "[INFO] pack"
PACK_FILE="$(npm pack | tail -n1 | tr -d '\r')"
PKG_VERSION="$(node -p "require('./package.json').version")"
DEST_FILE="bcdice-${PKG_VERSION}-${CUSTOM_SUFFIX}.tgz"
DEST_PATH="${VENDOR_DIR}/${DEST_FILE}"

if [[ -f "${DEST_PATH}" ]]; then
  TS="$(date +%Y%m%d%H%M%S)"
  mv "${DEST_PATH}" "${ARCHIVE_DIR}/${DEST_FILE%.tgz}-${TS}.tgz"
  echo "[INFO] archived old tgz: ${ARCHIVE_DIR}/${DEST_FILE%.tgz}-${TS}.tgz"
fi

mv "${PACK_FILE}" "${DEST_PATH}"

echo "[INFO] output tgz: ${DEST_PATH}"
echo "[INFO] output tgz file: ${DEST_FILE}"
