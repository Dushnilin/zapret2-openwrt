#!/bin/sh
set -eu

release_url=$1
key=$2
public_key=$3
keys=$(mktemp -d)
trap 'rm -rf "$keys"' EXIT
cp "$public_key" "$keys/"

luci=luci-app-zapret2_noarch.apk
apk verify --keys-dir "$keys" "$luci"

for package in zapret2_*.apk; do
    arch=${package#zapret2_}
    arch=${arch%.apk}
    index="packages-$arch.adb"
    apk verify --keys-dir "$keys" "$package"
    apk mkndx --keys-dir "$keys" --sign-key "$key" \
        --pkgname-spec "$release_url/\${name}_\${arch}.apk" \
        --output "$index" "$package" "$luci"
    apk verify --keys-dir "$keys" "$index"
done
