---
name: Run report
about: Report the result of running the verification steps (pass or fail)
title: "Run report: PASS/FAIL on <machine>"
labels: run-report
---

**Result:** PASS / FAIL / did not finish

**Repo commit** (`git rev-parse HEAD`):

**Checksums matched?** (`scripts/fetch.sh` printed `OK` for all 14 parts): yes / no

**Steps run:** fetch / audit / verify / recheck

**Machine:** OS, CPU cores, RAM, memory given to Docker

**Build time:**

**VERDICT block** (end of `scripts/verify.sh` output):

```
paste here
```

**If it failed:** last ~50 lines of `work/logs/verify.log`

```
paste here
```
