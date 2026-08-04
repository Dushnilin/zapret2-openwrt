#!/bin/bash
# Script to synchronize zapret2 package with upstream repository (bol-van/zapret2)
# Usage:
#   ./sync-upstream.sh          # Checks upstream release and updates Makefiles if newer
#   ./sync-upstream.sh --check  # Check status only (no modifications)
#   ./sync-upstream.sh --push   # Update Makefiles, commit and push to zap1 branch

set -eo pipefail

UPSTREAM_REPO="bol-van/zapret2"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
ZAP2_MAKEFILE="$SCRIPT_DIR/zapret2/Makefile"
LUCI_MAKEFILE="$SCRIPT_DIR/luci-app-zapret2/Makefile"

CHECK_ONLY=false
AUTO_PUSH=false

for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=true ;;
        --push) AUTO_PUSH=true ;;
        *) ;;
    esac
done

gh_fetch() {
    local url="$1"
    local token="${GH_TOKEN:-$GITHUB_TOKEN}"
    local res=""
    if [ -n "$token" ]; then
        res=$(curl -fsSL -H "User-Agent: Mozilla/5.0" -H "Authorization: Bearer $token" "$url" 2>/dev/null || true)
    fi
    if [ -z "$res" ]; then
        res=$(curl -fsSL -H "User-Agent: Mozilla/5.0" "$url" 2>/dev/null || true)
    fi
    echo "$res"
}

echo "==> Fetching latest release info from $UPSTREAM_REPO..."
RELEASE_JSON=$(gh_fetch "https://api.github.com/repos/$UPSTREAM_REPO/releases/latest")
TAG=$(echo "$RELEASE_JSON" | grep -oP '"tag_name":\s*"\K[^"]+' || true)

# Fallback: parse web redirect header if API rate limited
if [ -z "$TAG" ]; then
    LOC=$(curl -sI -H "User-Agent: Mozilla/5.0" "https://github.com/$UPSTREAM_REPO/releases/latest" | grep -i '^location:' | tr -d '\r\n' || true)
    TAG="${LOC##*/tag/}"
fi

if [ -z "$TAG" ]; then
    echo "ERROR: Failed to retrieve latest tag from $UPSTREAM_REPO"
    exit 1
fi

VER="${TAG#v}"

# Fetch commit SHA for tag (API first, HTML fallback)
TAG_REF_JSON=$(gh_fetch "https://api.github.com/repos/$UPSTREAM_REPO/git/refs/tags/$TAG")
OBJ_TYPE=$(echo "$TAG_REF_JSON" | grep -oP '"type":\s*"\K[^"]+' || true)
OBJ_SHA=$(echo "$TAG_REF_JSON" | grep -oP '"sha":\s*"\K[^"]+' || true)

if [ "$OBJ_TYPE" = "tag" ]; then
    TAG_OBJ_JSON=$(gh_fetch "https://api.github.com/repos/$UPSTREAM_REPO/git/tags/$OBJ_SHA")
    SHA=$(echo "$TAG_OBJ_JSON" | grep -oP '"sha":\s*"\K[^"]+' | tail -n 1 || true)
else
    SHA="$OBJ_SHA"
fi

if [ -z "$SHA" ]; then
    REL_HTML=$(curl -fsSL -H "User-Agent: Mozilla/5.0" "https://github.com/$UPSTREAM_REPO/releases/tag/$TAG" 2>/dev/null || true)
    SHA=$(echo "$REL_HTML" | grep -oP "/$UPSTREAM_REPO/commit/\K[a-f0-9]{40}" | head -n 1 || true)
fi

COMMIT_JSON=$(gh_fetch "https://api.github.com/repos/$UPSTREAM_REPO/commits/$SHA")
DATE=$(echo "$COMMIT_JSON" | grep -oP '"date":\s*"\K[^"]+' | head -n 1 | cut -dT -f1 || true)
if [ -z "$DATE" ]; then
    DATE=$(date -u +%Y-%m-%d)
fi

CUR_VER=$(grep -oP '^PKG_VERSION:=\K.*' "$ZAP2_MAKEFILE" || true)
CUR_SHA=$(grep -oP '^PKG_SOURCE_VERSION:=\K.*' "$ZAP2_MAKEFILE" || true)

echo "--------------------------------------------------------"
echo " Upstream latest release : $TAG (Version: $VER, Commit: ${SHA:0:8}, Date: $DATE)"
echo " Current repository pin  : Version: $CUR_VER, Commit: ${CUR_SHA:0:8}"
echo "--------------------------------------------------------"

if [ -n "$SHA" ] && [ "$SHA" = "$CUR_SHA" ]; then
    echo "SUCCESS: Repository is already up-to-date with upstream release $TAG."
    exit 0
fi

echo "--> New release detected!"

if [ "$CHECK_ONLY" = true ]; then
    echo "Run without --check to apply changes."
    exit 0
fi

echo "--> Updating Makefiles..."
sed -i -E "s/^PKG_VERSION:=.*/PKG_VERSION:=$VER/" "$ZAP2_MAKEFILE" "$LUCI_MAKEFILE"
if [ -n "$SHA" ]; then
    sed -i -E "s/^PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=$SHA/" "$ZAP2_MAKEFILE"
fi
sed -i -E "s/^PKG_SOURCE_DATE:=.*/PKG_SOURCE_DATE:=$DATE/" "$ZAP2_MAKEFILE"

echo "Updated $ZAP2_MAKEFILE:"
grep -E '^(PKG_VERSION|PKG_SOURCE_VERSION|PKG_SOURCE_DATE):=' "$ZAP2_MAKEFILE"

if [ "$AUTO_PUSH" = true ]; then
    echo "--> Committing and pushing to zap1 branch..."
    git add "$ZAP2_MAKEFILE" "$LUCI_MAKEFILE"
    git commit -m "zapret2: bump to $VER (nfqws2 $SHA)"
    git push origin zap1
    echo "Pushed to zap1. GitHub Actions will trigger build.yml to release $TAG."
else
    echo "Done! Review changes and commit/push to zap1 to trigger release build."
fi
