# FAQ

### So is the Riemann Hypothesis proven?

Not established yet. See the [status table](../README.md#status). Even if
every step here passes, that tells you a computer-checked proof exists and
proves the right statement. Mathematicians will still want to *understand*
the proof, and that work has barely started. But a passing check would be
extraordinary evidence, far stronger than a paper nobody has refereed yet.

### Why can't a computer just check all the zeros?

There are infinitely many. Computers have checked more than ten trillion,
all on the line (Platt and Trudgian, *Bulletin of the London Mathematical
Society*, 2021), but a single exception further out would make the hypothesis
false. Only a proof covers all of them.

### What does Lean actually check?

That each step follows from previous steps by the rules of logic, all the way
down to a handful of basic axioms. It does *not* check that the proof is
readable, elegant, or new.

### Could the AI have cheated?

That is exactly what steps 2–4 look for. The known ways to cheat in Lean are:

- skipping steps (`sorry`)
- assuming things (`axiom`)
- running code the kernel doesn't check (`native_decide`, `extern`, …)
- proving a different statement
- metaprograms that tamper with the compiled output

The static audit searches for the first four. The axiom check after the build
catches skipped steps and assumptions however they were hidden. `leanchecker`
catches tampering. If all of them pass, "cheating" would require a bug in
Lean's kernel itself.

### What if Lean's kernel has a bug?

It's possible, and soundness bugs have been found in proof checkers before.
The kernel is small and heavily scrutinised, though, and a bug that happened
to prove RH would itself be an astonishing coincidence. The strongest
further check is an independent kernel written by different people, such as
[nanoda](https://github.com/ammkrn/nanoda_lib). That isn't part of this repo yet.

### Why is it 17 million lines?

The note says the proof was produced quickly with heavy AI assistance and
expects "massive simplification". Long and inelegant doesn't mean wrong; the
checker doesn't care about length. But it does make human understanding much
harder.

### Who wrote this repository?

This repo is an independent verification harness. It is not affiliated with
the proof's authors and does not endorse the claim.

### I'm a mathematician. How can I help?

Read the top of the proof ([guide](reading-the-proof.md)), check that the four
GRH statements in `Statements.lean` mean what they should, and help map the
announcement's 20-step timeline onto the Lean folders.
