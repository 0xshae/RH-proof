# Checking the claimed Lean proof of the Riemann Hypothesis

In November 2026 a [short note](remark.pdf) announced a proof of the Riemann
Hypothesis, made with the help of Claude, and published it **only** as a
computer-checked proof written in [Lean](https://lean-lang.org). There is no
human-readable paper yet.

This repository is a step-by-step, reproducible way for **anyone** to check
that claim themselves, and to understand what "checked" actually means.
You don't need to be a mathematician. You do need some patience: the proof is
17 million lines long.

> **This repo does not say the Riemann Hypothesis is proven.** It is a neutral
> procedure. The [status table](#status) below reports what each step found,
> including failures.

---

## Status

| Step | What it checks | Result |
|---|---|---|
| 1. Fetch | The files you download are byte-for-byte the ones audited here | ✅ hashes pinned |
| 2. Static audit | No skipped steps (`sorry`), no new axioms, no kernel bypasses, correct statement | ✅ no red flags |
| 3. Kernel build | Lean's kernel checks every step; only standard axioms are used | ⏳ not yet run |
| 4. Re-check | `leanchecker` replays the compiled proof through the kernel again | ⏳ not yet run |

**Want to look inside?** [How to read the proof](docs/reading-the-proof.md)
walks from the final theorem down to where the real difficulty lives.
Questions like "so is it proven?" are answered in the [FAQ](docs/faq.md).

---

## The problem, in four steps

**1. Primes are irregular.** 2, 3, 5, 7, 11, 13, … There is no simple formula
for the next prime, but their *overall* count follows a pattern: up to a
number *x*, there are roughly *x* / ln(*x*) primes.

**2. The question is how good that estimate is.** In 1859 Bernhard Riemann
found that the error in this estimate is controlled by a single function, the
**zeta function**:

  ζ(s) = 1 + 1/2ˢ + 1/3ˢ + 1/4ˢ + …

Here *s* can be a complex number, a point on a 2D plane.

**3. What matters is where zeta equals zero.** Zeta is zero at −2, −4, −6, …
(the "trivial zeros", which are well understood). All its other zeros lie in a
vertical strip between 0 and 1. Every one found so far, more than ten trillion,
lies exactly on the middle line, where the real part is ½.

**4. The Riemann Hypothesis says *all* of them do.** If it's true, prime
numbers are as regular as they could possibly be. It has been open for over
165 years and is one of the Clay Millennium Prize problems.

Checking zeros by computer can never prove it, because there are infinitely
many. Only a proof can.

## What "a computer checked the proof" means

Lean is a programming language for writing mathematical proofs. At its core
is a small program called the **kernel**, which checks each step of a proof
against the rules of logic. If any step doesn't follow, the build fails.

That gives very strong guarantees, but only about three things. Those three
things are exactly what this repo checks:

1. **Was the right statement proved?** A perfect proof of the wrong
   statement is worthless. The proof must prove Mathlib's `RiemannHypothesis`.
   [Mathlib](https://github.com/leanprover-community/mathlib4) is the shared
   library of mathematics written by the Lean community, and its definition
   was written by people other than the proof's authors:
   ```lean
   def RiemannHypothesis : Prop :=
     ∀ (s : ℂ) (_ : riemannZeta s = 0) (_ : ¬∃ n : ℕ, s = -2 * (n + 1)) (_ : s ≠ 1),
       s.re = 1 / 2
   ```
   In words: *for every complex number s, if ζ(s) = 0, s is not a trivial
   zero, and s ≠ 1, then the real part of s is ½.*

2. **Were any steps skipped?** Lean lets you write `sorry` to mean "trust me"
   or declare an `axiom`, which is a statement accepted without proof. Either
   would make the result meaningless.

3. **Was the kernel bypassed?** A few features (`native_decide`, `extern`,
   `implemented_by`, `unsafe`, …) let code run *outside* the kernel's checks.

The final test is the command `#print axioms riemannHypothesis`, which lists
everything the proof ultimately rests on. A sound proof shows only Lean's
three standard axioms: `propext`, `Classical.choice` and `Quot.sound`. Nearly
all of Mathlib relies on the same three.

**What the check does *not* tell you:** who wrote the proof, whether it is
readable, or whether the ideas are new. It also assumes that Lean's kernel
itself has no bugs. That is a small, heavily scrutinised piece of code, but it
isn't nothing.

## Run it yourself

Requirements: macOS or Linux, `curl`, and [Docker](https://www.docker.com/)
for step 3.

```bash
./scripts/fetch.sh    # 1. download ~240 MB, verify checksums, extract into work/
./scripts/audit.sh    # 2. static audit, ~2 minutes, no Lean needed
./scripts/verify.sh   # 3. full kernel build in a sandbox, many hours
./scripts/recheck.sh  # 4. optional independent replay, hours more
```

Step 3 needs a big machine. The proof is about eight times the size of
Mathlib. In Docker Desktop, give the VM as much memory as you can
(Settings → Resources).

Step 3 runs the proof's code inside a container with **networking switched
off**, as an unprivileged user, so it can't touch your files or the internet.
It can be stopped and restarted, and resumes where it left off.

## What we found so far

From the static audit (`scripts/audit.sh`):

- `Main.lean` states `theorem riemannHypothesis : RiemannHypothesis`. That is
  Mathlib's definition, not redefined anywhere in the proof.
- Mathlib is the official repository at commit
  [`0df444a`](https://github.com/leanprover-community/mathlib4/commit/0df444a360eaa60ab8c11dca51a86af692955474)
  (Aug 2026). Lean version `v4.33.1`.
- Across all 175,187 files there are zero `sorry`, `admit`, `axiom`,
  `native_decide`, `implemented_by`, `extern` or `unsafe`.
- Code that runs during the build was read by hand. Five tiny `BuildAid`
  files only hide names from Lean's lemma-search tool. One file
  (`CutCptCopy.lean`) creates copies of theorems, but each copy is re-checked
  by the kernel. One file adds a helper to the `positivity` tactic, which is
  standard practice.
- The proof is about 17.4 million lines, roughly eight times the size of all
  of Mathlib, and `Main` depends on every file.
- All 9 dependencies come from the official `leanprover` and
  `leanprover-community` GitHub organisations.

### A caveat on the "Generalized" Riemann Hypothesis claims

`Main.lean` also claims four results about Dirichlet L-functions, a case of
the Generalized Riemann Hypothesis. **Those four statements are written by the
proof's authors** (in `Statements.lean`), not taken from Mathlib, so the
computer can only confirm they are *proved*. Whether they *mean* GRH is for a
human to judge. They read correctly to us, and step 3 prints them in full so
you can judge too. The headline `RiemannHypothesis` claim does not have this
caveat.

## Repository layout

```
remark.pdf             the original announcement
checksums/             SHA-256 hashes of the exact archive audited here
scripts/fetch.sh       step 1
scripts/audit.sh       step 2
scripts/verify.sh      step 3 (uses verify/)
scripts/recheck.sh     step 4
verify/Verify.lean     the questions we ask Lean at the end
verify/Dockerfile      the sandbox
docs/                  guides
```
