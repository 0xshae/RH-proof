#!/usr/bin/env bash
# Step 3: build the whole proof inside a sandbox and ask Lean's kernel what it proves.
#
# Needs Docker. Safe to stop and re-run: finished files are kept in a Docker
# volume, so the build resumes where it left off.
#
# Output: work/logs/verify.log, and a verdict at the end.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$ROOT/work/proof/lean" ] || { echo "Run scripts/fetch.sh first." >&2; exit 2; }

IMAGE=rh-verify
VOLUME=rh-verify-build
LOG="$ROOT/work/logs/verify.log"
mkdir -p "$ROOT/work/logs"

echo "==> Building the sandbox image"
docker build -q -t "$IMAGE" -f "$ROOT/verify/Dockerfile" "$ROOT" >/dev/null

echo "==> Phase 1 (network on): fetch Mathlib"
docker run --rm \
  -v "$VOLUME:/home/lean/proof" \
  -v "$ROOT/work/proof/lean:/src:ro" \
  "$IMAGE" /home/lean/in-container.sh deps 2>&1 | tee "$LOG"

echo "==> Phase 2 (network off): build and check the proof"
docker run --rm --network none \
  -v "$VOLUME:/home/lean/proof" \
  -v "$ROOT/verify:/verify:ro" \
  "$IMAGE" /home/lean/in-container.sh build 2>&1 | tee -a "$LOG"

echo
echo "================ VERDICT ================"
# Lean may wrap the axiom list over several lines; join them before reading it.
axioms=$(tr '\n' ' ' < "$LOG" | grep -oE "'riemannHypothesis' depends on axioms: \[[^]]*\]" | tail -1 || true)
if ! grep -q "CHECK 1 PASS" "$LOG"; then
  echo "FAIL: the statement check did not pass (see $LOG)"; exit 1
fi
if [ -z "$axioms" ]; then
  echo "FAIL: Lean did not report the axioms (see $LOG)"; exit 1
fi
echo "Lean reports: $axioms"
if ! grep -q "CHECK 4 PASS" "$LOG"; then
  echo "FAIL: the extra (GRH) statement check did not pass (see $LOG)"; exit 1
fi
# Every theorem's axiom list, main and extra, must be within the standard three.
extra=$(tr '\n' ' ' < "$LOG" | grep -oE "depends on axioms: \[[^]]*\]" \
        | sed -E 's/.*\[(.*)\]/\1/' | tr -d ' ' | tr ',' '\n' | grep . | sort -u \
        | grep -vxE 'propext|Classical\.choice|Quot\.sound' || true)
if [ -z "$extra" ]; then
  echo "PASS: the proof was checked by Lean's kernel, proves Mathlib's RiemannHypothesis,"
  echo "      and every claimed theorem uses only Lean's three standard axioms."
  echo "      The four GRH statements are the authors' own definitions; read them in $LOG."
else
  echo "FAIL: unexpected axioms:"; printf '  %s\n' $extra; exit 1
fi
