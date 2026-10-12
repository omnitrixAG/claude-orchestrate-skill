# Daily orchestration ledger

## Now

- Active task: none in flight. Calibration is closed; the first bounded real assignment awaits user selection and approval.
- Exact next command: `git status --short --branch`.

## Next

1. Select the first real ticket inside the promoted scope: scoped build, red test already written, small blast radius, nothing production-touching.
2. Write one lane pack for it from `lane-pack.md` and dispatch it with `dispatch.ps1 -Backend codex` on its own worktree and branch.
3. Rerun the tests independently, check changed paths against the scope list, then validate per `validator-procedure.md`.
4. Decide pending approvals: push of `main` and teardown of course-practice worktrees.

## Blocked

- First real dispatch: blocked on the user choosing a ticket and approving dispatch.
- Merge, push, deployment, and worktree deletion: blocked on explicit user approval.

## State

- Branch `main` at `73f3919` (reusable baseline), one commit ahead of `origin/main`, not pushed.
- Untracked by design: `module6-correction-pack.md`, `module6-rehearsal-pack.md` (course-history artifacts).
- Self-check `scripts/check.sh`: 61 passed, 1 failed (`install.sh silent about the symlink`); the failure predates this ledger update and comes from symlink creation under Windows Git Bash.
- Calibration result: `gpt-5.6-sol` on Codex, reasoning `medium`, promoted at 3/3 green with 0 P1; the `claude-opus-4-8` validator returned PASS on all three tickets.
  - Evidence root: `C:\Users\jakel\module7-calibration-evidence\2026-10-11-rerun` (`final-scorecard.md`, `promotion-status.txt`, `validators\`).
  - Earlier run scored HOLD and is preserved at `C:\Users\jakel\module7-calibration-evidence\2026-10-11`; it was excluded from the model score as a builder sandbox infrastructure failure.
  - Frozen pack hashes re-verified on 2026-10-12: 3/3 match. Any pack change requires re-calibration.
- Promotion scope: scoped build with red tests and small blast radius only. Not hard builds, not validation, never production-touching work.
- Hold list: no model is currently held; only `gpt-5.6-sol` was calibrated.
- Lane profile: `C:\Users\jakel\.codex\lane.config.toml` (model `gpt-5.6-sol`, effort `medium`, `workspace-write`, network off). The `unelevated` Windows sandbox is a temporary workaround.
- Validator: `claude-opus-4-8` per `validator-procedure.md`. HTTP 429 usage limits interrupted four validator invocations during the rerun; every failed attempt is preserved.
- Preserved worktrees, untouched without approval: `C:\Users\jakel\module7-calibration-worktrees-rerun\*` plus the other calibration and qualification worktrees of the client repository; ten course-practice worktrees on this repository.
- Concurrency cap: four builders plus one validator.
- Previous ledger archived verbatim in `NEXT.archive.md`.

### Windows daily procedure

1. Read `CLAUDE.md`, `AGENTS.md`, the repository map if present, and `NEXT.md`.
2. Run `git status --short`, `git log --oneline -5`, `git worktree list`, and baseline tests.
3. Use one non-main worktree per lane; start with one builder and do not exceed four builders.
4. Measure capacity before increasing concurrency; verify changed paths before reading diffs.
5. Independently rerun tests after the agent exits; never trust the agent's success claim.
6. On failure, record the precise evidence and issue a fresh correction pack; after two failed attempts, split the scoped unit.
7. Record exact commands and worktree paths before session end or context compaction.
8. Require explicit approval before commit, merge, push, deployment, or worktree deletion.
