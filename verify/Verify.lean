/-
  Step 3, the final question we ask Lean, once the whole proof has been built.

  Building the proof means Lean's kernel has already checked every single step.
  What is left is to make sure the thing that was proved is the thing we care
  about, and that it rests on nothing beyond standard mathematics.
-/
import Main

open Lean Elab Command

/- Check 1: the statement is exactly Mathlib's `RiemannHypothesis`.

   We compare the theorem's type as a raw kernel term against the constant
   `RiemannHypothesis`, and ask which module defined that constant. Notation,
   macros or a look-alike name cannot fool this comparison. -/
run_cmd do
  let env ← getEnv
  let some thm := env.find? ``riemannHypothesis
    | throwError "FAIL: no theorem named riemannHypothesis"
  unless thm.type == .const ``RiemannHypothesis [] do
    throwError "FAIL: riemannHypothesis does not have type RiemannHypothesis, it has {thm.type}"
  let some idx := env.getModuleIdxFor? ``RiemannHypothesis
    | throwError "FAIL: RiemannHypothesis is not imported from any module"
  let mod := env.header.moduleNames[idx.toNat]!
  unless mod == `Mathlib.NumberTheory.LSeries.RiemannZeta do
    throwError "FAIL: RiemannHypothesis comes from {mod}, not from Mathlib"
  logInfo m!"CHECK 1 PASS: statement is Mathlib's RiemannHypothesis, defined in {mod}"

/- Check 2: print the definition, so a human can read what was proved. -/
#print RiemannHypothesis

/- Check 3: list every axiom the proof depends on, all the way down.
   A sound proof of a standard theorem should show only:
     propext, Classical.choice, Quot.sound
   These are the three standard axioms every Mathlib proof uses.
   Anything else (sorryAx, Lean.ofReduceBool, a custom axiom) means the proof
   assumes something it did not prove. scripts/verify.sh checks this list. -/
#print axioms riemannHypothesis

/- Extra claims: the Generalized Riemann Hypothesis for Dirichlet L-functions.

   Main.lean also claims four statements about Dirichlet L-functions. Unlike
   RiemannHypothesis, these statements are NOT from Mathlib: the proof's authors
   wrote them, in Statements.lean. So the kernel can only tell us they are
   proved; a human has to read the definitions below and judge whether they
   say what GRH says. We print each one, check each theorem has exactly that
   type, and list its axioms. -/
run_cmd do
  let env ← getEnv
  for (thm, stmt) in [(``LFunction_ne_zero_of_half_lt_re, ``DirichletLNonvanishingRightOfHalf),
                      (``LFunction_eq_zero_re, ``DirichletLZerosOnLine),
                      (``LFunction_eq_zero_re_of_isPrimitive, ``PrimitiveDirichletLZerosOnLine),
                      (``riemannZeta_eq_zero_re, ``RiemannZetaZerosOnLine)] do
    let some ci := env.find? thm | throwError "FAIL: missing {thm}"
    unless ci.type == .const stmt [] do throwError "FAIL: {thm} does not have type {stmt}"
  logInfo "CHECK 4 PASS: each extra theorem has exactly the type printed below"

#print DirichletLNonvanishingRightOfHalf
#print DirichletLZerosOnLine
#print PrimitiveDirichletLZerosOnLine
#print RiemannZetaZerosOnLine
#print axioms LFunction_ne_zero_of_half_lt_re
#print axioms LFunction_eq_zero_re
#print axioms LFunction_eq_zero_re_of_isPrimitive
#print axioms riemannZeta_eq_zero_re
