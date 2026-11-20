#!/usr/bin/env bash
# Runs inside the container. Called by scripts/verify.sh; not meant to be run directly.
set -euo pipefail
PROOF=/home/lean/proof

case "${1:-}" in
  deps)
    # Network ON. Copy the proof into the build volume and fetch Mathlib.
    if [ ! -f "$PROOF/.copied" ]; then
      echo "==> Copying proof source into build volume"
      cp -R /src/. "$PROOF/"
      touch "$PROOF/.copied"   # only after a complete copy, so an interrupted copy is redone
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
  recheck)
    # Network OFF. Replay every compiled declaration through the kernel again,
    # this time loading the finished files instead of compiling source. This
    # catches "environment hacking": metaprograms that sneak unchecked
    # declarations into the compiled output.
    cd "$PROOF"
    if [ "${2:-}" = "--fresh" ]; then
      echo "==> Replaying everything Main depends on into an empty environment (single-threaded, very slow)"
      lake env leanchecker --fresh Main
    else
      echo "==> Re-checking every compiled file in parallel"
      lake env leanchecker
    fi
    echo "LEANCHECKER PASS"
    ;;
  *)
    echo "usage: in-container.sh deps|build|recheck [--fresh]" >&2; exit 2 ;;
esac
