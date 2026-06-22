#!/usr/bin/env bash

set -euo pipefail

identity_name="MacWindowSwitcher Local Development"
keychain="$(security default-keychain -d user | tr -d '"')"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/mac-window-switcher-signing.XXXXXX")"
password="$(openssl rand -hex 16)"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if security find-identity -v -p codesigning | grep -Fq "\"$identity_name\""; then
  echo "Signing identity already exists: $identity_name"
  exit 0
fi

cat > "$work_dir/openssl.cnf" <<CONFIG
[req]
distinguished_name = subject
x509_extensions = extensions
prompt = no

[subject]
CN = $identity_name

[extensions]
basicConstraints = critical,CA:TRUE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
CONFIG

openssl req -new -newkey rsa:2048 -nodes -x509 -days 3650 \
  -config "$work_dir/openssl.cnf" \
  -keyout "$work_dir/key.pem" \
  -out "$work_dir/certificate.pem"

openssl pkcs12 -export \
  -inkey "$work_dir/key.pem" \
  -in "$work_dir/certificate.pem" \
  -name "$identity_name" \
  -passout "pass:$password" \
  -out "$work_dir/identity.p12"

security import "$work_dir/identity.p12" \
  -k "$keychain" \
  -P "$password" \
  -T /usr/bin/codesign
security add-trusted-cert -d -r trustRoot -p codeSign -k "$keychain" "$work_dir/certificate.pem"

echo "Created signing identity: $identity_name"
echo "The first build may ask for permission to access its private key."
