#!/usr/bin/env bash
# Step 2: read the source for known ways a Lean "proof" can cheat, without building anything.
#
# This is a fast first pass, not the final word. A text search can't see
# everything. The real check is the kernel build in step 3. But if anything
# here FAILs, the proof is not trustworthy and there is no point building it.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/work/proof/lean/src"
LEAN="$ROOT/work/proof/lean"
[ -d "$SRC" ] || { echo "Run scripts/fetch.sh first." >&2; exit 2; }

fails=0
pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails + 1)); }
note() { printf '  \033[33mNOTE\033[0m  %s\n' "$1"; }

# The source is ~17M lines, so scan it once for every pattern below and
# only re-search the handful of files that matched.
ALL='sorry|admit|axiom|native_decide|ofReduceBool|implemented_by|extern|unsafe|skipKernelTC|debug\.|RiemannHypothesis|namespace Mathlib|run_cmd|run_elab|run_meta|addDecl|modifyEnv'
echo "Scanning $(find "$SRC" -name '*.lean' | wc -l | tr -d ' ') files (takes a minute or two)..."
CANDIDATES=()
while IFS= read -r f; do CANDIDATES+=("$f"); done < <(grep -rlE "$ALL" "$SRC")
matching() { [ "${#CANDIDATES[@]}" -eq 0 ] || grep -lE "$1" "${CANDIDATES[@]}"; }

# must_be_zero <pattern> <what it is> <why it matters>
must_be_zero() {
  local files n; files=$(matching "$1"); n=$(printf '%s' "$files" | grep -c . || true)
  if [ "$n" -eq 0 ]; then pass "no $2"; else fail "$2 found in $n file(s): $3"; printf '%s\n' "$files" | head -5 | sed "s|$SRC/|          |"; fi
}

echo "== What theorem is claimed?"
if grep -qE '^theorem riemannHypothesis : RiemannHypothesis :=' "$SRC/Main.lean"; then
  pass "Main.lean states 'theorem riemannHypothesis : RiemannHypothesis'"
else
  fail "Main.lean does not state the expected theorem"
fi
if [ -n "$(matching '^\s*(def|abbrev|structure|class|inductive|opaque|notation|macro|syntax)\s+(_root_\.)?RiemannHypothesis\b')" ]; then
  fail "the proof defines its own 'RiemannHypothesis', which could quietly change what is being proved"
else
  pass "'RiemannHypothesis' is not redefined; it comes from Mathlib"
fi

echo "== Is Mathlib the real, unmodified Mathlib?"
if grep -qE 'git = "https://github.com/leanprover-community/mathlib4"' "$LEAN/lakefile.toml"; then
  pass "Mathlib is fetched from the official repository"
else
  fail "Mathlib comes from somewhere other than the official repository"
fi
urls=$(grep -oE '"url": *"[^"]+"' "$LEAN/lake-manifest.json" | cut -d'"' -f4)
bad=$(printf '%s\n' "$urls" | grep -vE '^https://github\.com/(leanprover-community|leanprover)/[A-Za-z0-9_.-]+$' || true)
if [ -z "$bad" ]; then
  pass "all $(printf '%s\n' "$urls" | grep -c .) dependencies come from official Lean / Mathlib GitHub organisations"
else
  fail "dependencies from unexpected sources:"; printf '          %s\n' $bad
fi
note "Mathlib pinned at commit $(grep -oE 'rev = "[0-9a-f]+"' "$LEAN/lakefile.toml" | head -1 | cut -d'"' -f2)"
note "Lean toolchain: $(cat "$LEAN/lean-toolchain")"
matching '^\s*namespace Mathlib' | sed "s|$SRC/|          |"
note "reviewed: the file above registers a 'positivity' tactic extension (standard Mathlib pattern); it only helps find proofs, the kernel still checks them"

echo "== Unfinished or assumed steps"
must_be_zero '\bsorry\b'  "'sorry'"  "a placeholder that skips a proof step"
must_be_zero '\badmit\b'  "'admit'"  "a placeholder that skips a proof step"
must_be_zero '^\s*(private\s+|protected\s+)?axiom\b' "new axioms" "an axiom is a statement accepted without proof"

echo "== Ways to bypass the kernel (Lean's trusted proof checker)"
must_be_zero '\bnative_decide\b'  "'native_decide'"     "trusts compiled code instead of the kernel"
must_be_zero 'ofReduceBool'       "'Lean.ofReduceBool'" "trusts compiled code instead of the kernel"
must_be_zero 'implemented_by'     "'implemented_by'"    "swaps in different code at runtime"
must_be_zero '@\[extern'          "'@[extern]'"         "links to code outside Lean"
must_be_zero '\bunsafe\b'         "'unsafe'"            "unchecked code"
must_be_zero 'skipKernelTC|debug\.' "debug options"     "can switch off kernel checking"

echo "== Metaprograms (code that runs while building; reviewed by hand)"
matching 'run_cmd|run_elab|run_meta|addDecl|modifyEnv' | sed "s|$SRC/|          |"
note "reviewed: BuildAid/* only hide namespaces from lemma search; CutCptCopy adds copies via addDecl, which the kernel re-checks"

echo
if [ "$fails" -eq 0 ]; then
  echo "Static audit: no red flags found. Next: build and ask the kernel (step 3)."
else
  echo "Static audit: $fails red flag(s). Do not trust this proof until they are explained."
fi
exit "$fails"
