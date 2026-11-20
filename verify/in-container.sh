#!/usr/bin/env bash
# Runs inside the container. Called by scripts/verify.sh; not meant to be run directly.
set -euo pipefail
PROOF=/home/lean/proof

case "${1:-}" in
  deps)
    # Network ON. Copy the proof into the build volume and fetch Mathlib.
    if [ ! -f "$PROOF/lakefile.toml" ]; then
      echo "==> Copying proof source into build volume"
      cp -R /src/. "$PROOF/"
    fi
    cd "$PROOF"
    echo "==> Fetching Mathlib at the pinned commit, plus its prebuilt files"
    # The prebuilt files come from Mathlib's own CI. To rebuild Mathlib from
    # scratch as well, skip this line; the build step will then compile it.
    lake exe cache get
    ;;
  build)
    # Network OFF. Compile every file; the kernel checks every proof step.
    cd "$PROOF"
    echo "==> Building the proof ($(find src -name '*.lean' | wc -l) files). This takes many hours."
    lake build Main
    echo "==> Asking Lean what was proved"
    lake env lean /verify/Verify.lean
    ;;
  *)
    echo "usage: in-container.sh deps|build" >&2; exit 2 ;;
esac
