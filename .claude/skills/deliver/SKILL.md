---
name: deliver
description: End-of-session Crew delivery report - what was built against the briefing, STOP compliance, pre-existing tests touched, gate result, deviations, and the next step. Use when a slice is done, the session is wrapping up, you need to hand back to the architect, resume next sitting, or invoke /deliver.
---

# deliver - Crew slice handback / resume report

Produce a compact, honest report at the end of a Crew session. It serves two readers: the **architect** (who reviews and records it) and a **future session** resuming the slice. Do NOT commit or push as part of `/deliver` - the slice ships through its normal PR flow; this only reports.

## Report structure

1. **Branch + state** - branch, HEAD short SHA, working tree status (clean / list dirty), open PR number if any, upstream sync.
2. **Gate** - if the architect's harness registered the gate, paste `<git-dir>/crew_gate/pass_<sha of HEAD>` verbatim (`git rev-parse --absolute-git-dir` gives the dir). Otherwise run the gate command from `.memory/project_stack.md` on the committed tree and paste its summary. No green gate for HEAD = say so and why. Gate hit the 2-round cap = say so and stop here. **The gate runs AFTER the PR is open - `git push` and `gh pr create` never wait for it.** Still running when you report = say "gate running" and paste the pass file when it lands; red = fix on the same branch and push again.
3. **Deliverables vs briefing** - for each item of the briefing's §1 (FIXO POR DECISAO), mark **done / partial / not-done**, checked against §3 (tests to write) and the acceptance line, not against "I wrote code".
4. **STOP** - each STOP of §5, including the fixed test-against-spec line: honored, or triggered (then: which test, which §1 line, why).
5. **Pre-existing tests touched** - the pass file's `modified_tests=`, or, without it, the `M`/`R`/`D` test files in `git diff --name-status $(git merge-base HEAD origin/develop) HEAD`. One line each: what changed and WHY the briefing required it. Empty = write "none". A test changed to make the gate pass, without a §1 reason, is a defect to report, not to hide.
6. **Beyond scope** - anything delivered ABOVE the briefing (an extra guard, a technical improvement, a refactor). Flag it EXPLICITLY so the architect can separate a ratifiable improvement from scope-creep.
7. **Tests** - which tests are new (by §3 item), counts from the gate, and any failure (paste it - never claim green if red).
8. **What the sponsor's smoke should exercise** - the real gate is the install on a clean Windows VM (BL-7), not a green suite. Name the two or three paths that carry the risk of this slice (the compiled QGIS opening, a native algorithm running, a project loading, fresh install, install next to an official QGIS without touching it). A smoke that did not run on the VM is a declared gap with numbered steps to reproduce, never "done".
9. **Next step** - open PR against the base branch / continue (state exactly what's left) / BLOCKED on X (name the blocker and its owner).

## Rules

- Behavioral and honest: if tests fail, say so with output; if a deliverable was skipped, say which and why. Done-and-verified stated plainly, gaps surfaced.
- Reference file paths + SHAs so the architect can review precisely.
- In a develop-based flow `Closes #N` is INERT - the issue is linked and closed manually; do not assume the PR closes it.
- Do NOT touch the architect's repo (briefings, `INDEX.md`, decisions) - that is the architect's.
- Never write in `crew_gate/` (pass_, rounds_): only the gate script writes there.
- Review and explanation go in this report, never in the PR body or PR comments.
- Keep it compact - a scannable report, not a narrative re-telling of the session.
