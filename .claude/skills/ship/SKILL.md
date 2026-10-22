---
name: ship
description: Stage, commit (granular, meaningful message, NEVER Co-Authored-By), push the slice branch, and verify a clean working tree. Use when the user says "ship", "save and push", "commit and push", or invokes /ship.
---

# ship - commit + push + clean working tree

Save the current work: stage, commit with a meaningful message, push the slice branch, and leave a clean working tree. The foot-gun to avoid: "commit everything blindly" ships junk, secrets or half-done work - so stage deliberately.

## Steps

1. **Show first.** `git status --short` + `git diff --stat`. List untracked files SEPARATELY from tracked modifications.
2. **Stage deliberately.** Tracked modifications by default (`git add -u`). For untracked files, list them and confirm before staging - never blind-add scratch, binary or secret files. Respect `.gitignore`.
   **Non-negotiable:** never stage `.env.local` / `.env.*.local`, tokens, or credentials. If one appears in the diff, STOP and report it - a secret pushed once is a secret rotated, not removed. Never stage an `.exe`, a `.dll`, a build output folder or downloaded dependencies (builds and the dependency tree stay out of git).
   **No em dash nor en dash** in the commit message or in any staged text file (D-IMAN-034).
3. **Message.** Use the user's argument if given; otherwise generate from the diff. Granular over monolithic. No icons. Imperative, specific, Conventional Commits (`feat/fix/test/docs/chore(scope): ...`), with the slice ID when there is one.
4. **NEVER Co-Authored-By or AI credits - in ANYTHING published.** No co-authorship trailer in commit messages and no `Co-Authored-By` / `Generated with Claude Code` (or similar) in PR titles/bodies, issues or comments.
5. **Push first, gate after.** Push the slice branch and open the PR as soon as the commits are ready - push and PR never wait for the gate. Run the gate on the pushed HEAD afterwards and report it in `/deliver` §2.
6. **Commit + push.** Normal `git commit` + `git push` to the slice branch only - never to `develop`/`main`, never `--force`.
   No exception: this Crew has no direct push to `develop`. A canonical release build, when it exists, comes with its own briefing.
7. **Verify + report.** `git status` clean and upstream sync `0  0` (`git rev-list --left-right --count @{u}...HEAD`). Report: branch, pushed SHA range, untracked files deliberately left out.

## Notes

- **Ship = open a PR, NOT merge.** The merge is the sponsor's.
- Nothing to commit = say so and stop; no empty commits.
