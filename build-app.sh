#!/usr/bin/env bash
# Baut ClaudeStatus als .app-Bundle mit LSUIElement (Menüleisten-only).
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${CONFIG:-release}"
APP_NAME="ClaudeStatus"
APP_DIR="build/${APP_NAME}.app"

# Version aus dem nächsten git-Tag ableiten (z. B. v0.3.0 → 0.3.0)
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
BUILD=$(git rev-list --count HEAD 2>/dev/null || echo "1")

echo "→ swift build -c ${CONFIG}"
swift build -c "${CONFIG}"

BIN_PATH="$(swift build -c "${CONFIG}" --show-bin-path)/${APP_NAME}"

echo "→ Bundle anlegen unter ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>de.thomashahn.ClaudeStatus</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Status</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

SELF_SIGN_NAME="ClaudeStatus Self Sign"
FORCE_AD_HOC="${FORCE_AD_HOC:-${CI:-}}"   # CI=true → ad-hoc

pick_signing_identity() {
    if [ -n "${SIGN_IDENTITY:-}" ]; then
        echo "${SIGN_IDENTITY}"; return
    fi
    if [ -n "${FORCE_AD_HOC}" ] && [ "${FORCE_AD_HOC}" != "false" ] && [ "${FORCE_AD_HOC}" != "0" ]; then
        return
    fi
    local list; list=$(security find-identity -v -p codesigning 2>/dev/null || true)
    for prefix in "Developer ID Application" "Apple Development" "Apple Distribution" "${SELF_SIGN_NAME}"; do
        local name
        name=$(printf '%s\n' "${list}" | sed -n "s/.*\"\(${prefix}[^\"]*\)\".*/\1/p" | head -n1)
        if [ -n "${name}" ]; then echo "${name}"; return; fi
    done
}

ensure_self_sign_identity() {
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"${SELF_SIGN_NAME}\""; then
        return 0
    fi
    echo "→ Lokales Code-Signing-Cert '${SELF_SIGN_NAME}' anlegen (einmalig)"
    local tmp; tmp=$(mktemp -d)
    cat > "${tmp}/openssl.cnf" <<CNF
[ req ]
distinguished_name = req_dn
prompt             = no
x509_extensions    = v3_req
[ req_dn ]
CN = ${SIGN_IDENTITY}
[ v3_req ]
basicConstraints     = critical, CA:false
keyUsage             = critical, digitalSignature
extendedKeyUsage     = critical, codeSigning
CNF

    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "${tmp}/key.pem" -out "${tmp}/cert.pem" \
        -days 3650 -config "${tmp}/openssl.cnf" >/dev/null 2>&1
    openssl pkcs12 -export -legacy \
        -inkey "${tmp}/key.pem" -in "${tmp}/cert.pem" \
        -out "${tmp}/cert.p12" -password pass: \
        -name "${SIGN_IDENTITY}" >/dev/null 2>&1

    local kc="$HOME/Library/Keychains/login.keychain-db"
    security import "${tmp}/cert.p12" -k "${kc}" -P "" \
        -T /usr/bin/codesign -T /usr/bin/security >/dev/null

    echo "→ Schlüssel für codesign freischalten – evtl. wirst du nach deinem Login-Passwort gefragt"
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" "${kc}" >/dev/null 2>&1 || \
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s "${kc}" || true

    rm -rf "${tmp}"
}

CHOSEN_IDENTITY="$(pick_signing_identity)"
if [ -z "${CHOSEN_IDENTITY}" ] && [ -z "${FORCE_AD_HOC}" ]; then
    ensure_self_sign_identity
    CHOSEN_IDENTITY="$(pick_signing_identity)"
fi

if [ -n "${CHOSEN_IDENTITY}" ]; then
    echo "→ Signatur mit '${CHOSEN_IDENTITY}'"
    codesign --force --deep --sign "${CHOSEN_IDENTITY}" "${APP_DIR}"
else
    echo "→ Fallback: Ad-hoc-Signatur"
    codesign --force --deep --sign - "${APP_DIR}"
fi

echo
echo "Fertig: ${APP_DIR}  (Version ${VERSION}, Build ${BUILD})"
echo "Starten:  open ${APP_DIR}"
echo "In den Programme-Ordner verschieben:  mv ${APP_DIR} /Applications/"
