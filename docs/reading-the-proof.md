# How to read the proof

The proof is 175,187 files and 17.4 million lines. Nobody reads that
front to back, not even its authors. But the **top** of the proof is short,
readable, and tells you exactly how the whole thing is put together. This
guide walks down from the final theorem, one link at a time.

All paths are inside `work/proof/lean/src/`, after running `scripts/fetch.sh`.

## Reading Lean in 60 seconds

```lean
theorem name (h : A) : B := proof
```

means: *"given a proof `h` of statement `A`, here is a proof of statement
`B`."* A `def ... : Prop := ...` defines a statement without proving it.
`∀` means "for every", `→` means "implies", `≠` means "not equal",
`s.re` is the real part of a complex number `s`.

## The chain from the top

### Link 1: `Main.lean`, the claim

```lean
theorem riemannHypothesis : RiemannHypothesis := rhOfAll
```

The final theorem just points at `rhOfAll`. `RiemannHypothesis` is Mathlib's
definition (see the [README](../README.md#what-a-computer-checked-the-proof-means)).

### Link 2: `Supplements/Kernels/MainTheorems.lean`, everything rests on one theorem

```lean
theorem allChi : UpperTheory.EveryCharacter := UpperTheory.FinalTheorems.everyCharacter

theorem rhOfAll : RiemannHypothesis := Formalism.VW.rh_of_every allChi
```

**This is the most important thing to understand about the proof's shape.**
Everything, RH and the GRH claims alike, is derived from a single statement
called `EveryCharacter`.

### Link 3: what `EveryCharacter` says

`Development/AutomorphicArithmetic/CharacterBoxes/EveryCharacter.lean`:

```lean
def UpperTheory.EveryCharacter : Prop :=
  ∀ (N : ℕ) [NeZero N] (χ : DirichletCharacter ℂ N) (s : ℂ),
    1 / 2 < s.re → (χ ≠ 1 ∨ s ≠ 1) → DirichletCharacter.LFunction χ s ≠ 0
```

In words: *for every Dirichlet L-function (a family of functions that
includes zeta), there are no zeros to the right of the line Re(s) = ½,*
except for zeta's pole at s = 1.

### Link 4: from "no zeros on the right" to "all zeros on the line"

`Formalism/GammaFactorNonvanishing/RhOfRight.lean` and `CritLine.lean`.

This part is **classical, short (about 60 lines), and uses only Mathlib**. It
is a good place to start reading Lean. The argument:

1. Suppose ζ(s) = 0 with Re(s) < ½.
2. Riemann's *functional equation* (`riemannZeta_one_sub` in Mathlib) relates
   ζ(s) to ζ(1 − s). It forces ζ(1 − s) = 0 as well.
3. But Re(1 − s) > ½, and `EveryCharacter` says there are no zeros there.
   Contradiction.
4. So Re(s) can be neither less than ½ nor greater than ½: it equals ½.

This step has been known since Riemann. Proving "no zeros to the right of ½"
is the entire difficulty. That is the open problem, and the other 17 million
lines are about it.

### Link 5: where `EveryCharacter` is proved

`Development/AutomorphicArithmetic/CharacterBoxes/MainConclusion.lean`:

```lean
theorem UpperTheory.FinalTheorems.everyCharacter : UpperTheory.EveryCharacter :=
  UpperTheory.FinalTheorems.everyCharacter_of_row UpperTheory.Gal.Int.galoisLocalGlobalStrong_recParameter

theorem UpperTheory.FinalTheorems.everyCharacter_of_row (h : ...) : UpperTheory.EveryCharacter :=
  UpperTheory.LiteratureTheorems.every_character_of_literature_of_vWin
    ⟨h, UpperTheory.Zero.LLC.recTExists, h⟩ (UpperTheory.One.vwin_of_row h)
```

From here down, the proof enters research-level number theory. Worth noticing:
`every_character_of_literature_of_vWin` takes a bundle called
`OpenLiteratureStatements`, which by its name is a package of results from the
mathematical literature. Here that bundle is **built from proofs**
(`⟨h, recTExists, h⟩`), not assumed. That is exactly what the axiom check in
step 3 confirms for the whole proof: nothing is taken on faith.

## The rest of the map

Below Link 5, the best guide is folder names. **These are the authors' labels,
read at face value.** We have not traced which folder does what
mathematically.

| Folder | Files | Suggests |
|---|---:|---|
| `Development/AbelianVarietyTheory` | 99,187 | abelian varieties, theta functions; the bulk of the proof |
| `Development/AutomorphicArithmetic` | 18,431 | automorphic forms, theta correspondence, Galois representations; contains the top of the proof |
| `Development/AutomorphicSpectrum` | 15,147 | spectral theory of automorphic forms |
| `Development/WeilBound` | 7,051 | Weil's bound / RH over finite fields, the "toy setting" the note describes |
| `GroundTheory/HeightsAndTheta` | 6,410 | heights and theta functions |
| `Formalism/LocalToGlobal` | 5,501 | local-to-global principles |
| `Formalism/PeriodIntegrals` | 4,350 | period integrals (GGP periods in the note) |
| `ReciprocityTheory/ReductiveGroups` | 2,799 | reductive groups, reciprocity |
| `CompanionTheory/SpectralGeometry` | 1,254 | spectral geometry |
| `PositivityTheory` | 449 | positivity (Weil's criterion is a positivity statement) |
| `Development/EtaleCohomology` | 1,398 | étale cohomology (Deligne's proof of Weil) |
| `Development/ResolutionOfSingularities` | 499 | resolution of singularities |
| `Supplements/Kernels` | 3 | the final assembly (Links 2–5) |

### Connecting to the note's timeline

The [announcement](../remark.pdf) lists 20 steps. Some match folder names
directly: theta lifts → `ThetaCorrespondence`, GGP/Bessel periods →
`PeriodIntegrals` and `BesselOrbitBounds`, the function-field "toy setting" →
`WeilBound`. Mapping all 20 properly needs someone who knows the mathematics.
Contributions are welcome.

## Try it yourself

Once step 3 has built the proof, you can ask Lean questions in the sandbox:

```bash
docker run --rm -it --network none -v rh-verify-build:/home/lean/proof rh-verify bash
cd proof
cat > /tmp/q.lean <<'EOF'
import Main
#check @UpperTheory.FinalTheorems.everyCharacter
#print axioms UpperTheory.FinalTheorems.everyCharacter
EOF
lake env lean /tmp/q.lean
```
