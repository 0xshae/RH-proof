#!/usr/bin/env bash
# Step 1: download the claimed proof and check it is exactly the archive we audited.
#
# - Downloads the 14 archive parts from the author's server.
# - Checks every part against the SHA-256 hashes pinned in checksums/.
#   If a single byte differs, this script stops. That means you are NOT
#   looking at the same files this repo describes.
# - Refuses archives that contain absolute paths, "..", or links.
# - Extracts into work/proof/. Nothing is built or executed here.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
BASE_URL="https://alpo.ge"
PARTS=14

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

mkdir -p "$WORK/download"
cd "$WORK/download"

echo "==> Downloading $PARTS parts from $BASE_URL"
for i in $(seq -w 1 "$PARTS"); do
  f="lean.tar.gz.part$i"
  [ -f "$f" ] && continue
  curl -sSfL --retry 3 -o "$f.tmp" "$BASE_URL/$f"
  mv "$f.tmp" "$f"
done

echo "==> Verifying each part against checksums/parts.sha256"
sha256 -c "$ROOT/checksums/parts.sha256"

echo "==> Joining parts and verifying the full archive"
cat lean.tar.gz.part* > "$WORK/lean.tar.gz"
(cd "$WORK" && sha256 -c "$ROOT/checksums/archive.sha256")

echo "==> Checking archive for unsafe paths or links"
if tar -tzf "$WORK/lean.tar.gz" | grep -qE '(^/|(^|/)\.\.(/|$))'; then
  echo "REFUSING: archive contains absolute or '..' paths" >&2; exit 1
fi
if tar -tvzf "$WORK/lean.tar.gz" | grep -qE '^[lh]'; then
  echo "REFUSING: archive contains links" >&2; exit 1
fi

echo "==> Extracting to work/proof/"
rm -rf "$WORK/proof"
mkdir -p "$WORK/proof"
tar -xzf "$WORK/lean.tar.gz" -C "$WORK/proof"

echo "Done. The proof is in work/proof/lean/ ($(find "$WORK/proof" -name '*.lean' | wc -l | tr -d ' ') Lean files)."
