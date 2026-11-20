#!/usr/bin/env bash
# Step 4 (optional, after step 3 passes): re-check the compiled proof with leanchecker.
#
# Step 3 trusts that what Lean compiled is what its kernel checked. A
# metaprogram could, in principle, slip a declaration into the compiled files
# without the kernel seeing it. leanchecker (bundled with Lean) reloads the
# compiled files and sends every declaration through the kernel again.
#
#   ./scripts/recheck.sh           parallel, per file (hours)
#   ./scripts/recheck.sh --fresh   everything from an empty start, single-threaded (much longer)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/work/logs/recheck.log"
mkdir -p "$ROOT/work/logs"

docker run --rm --network none \
  -v rh-verify-build:/home/lean/proof \
  rh-verify /home/lean/in-container.sh recheck "${1:-}" 2>&1 | tee "$LOG"

echo
if grep -q "LEANCHECKER PASS" "$LOG"; then
  echo "PASS: every compiled declaration was accepted by the kernel on replay."
else
  echo "FAIL: leanchecker did not finish cleanly (see $LOG)"; exit 1
fi
