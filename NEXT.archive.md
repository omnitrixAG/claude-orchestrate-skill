# Ledger archive

Entries rolled out of NEXT.md verbatim, newest first.

## Archived 2026-10-12 (ledger as committed in 73f3919)

# Daily orchestration ledger

## Now

- Active task: establish the reusable baseline required before Module 7 ticket qualification.
- Exact next command: `git status --short --branch`.

## Next

- Review the baseline diff and approve the first baseline commit when ready.
- Qualify three closed tickets by proving the supplied regression test is red at the pre-fix commit and green at the known fixed commit.
- Prepare one five-block lane pack per qualified ticket before any model calibration run.

## Blocked

- Ticket qualification is pending; no calibration run may begin until all three red/green histories are recorded.
- Staging, committing, merging, pushing, deployment, and worktree deletion require explicit approval.

## State

- Repository branch: `main`.
- Reusable runner: `dispatch.ps1`.
- Reusable lane template: `lane-pack.md`.
- Result contracts: `lane-report.schema.json` and `dispatch-result.schema.json`.
- Independent validator procedure: `validator-procedure.md`, pinned to `claude-opus-4-8`.
- Default Codex lane model: `gpt-5.6-sol`.
- Module 6 packs remain preserved as course-history artifacts and are excluded from the proposed baseline commit.
- Existing worktrees and outputs remain untouched pending explicit cleanup approval.

### Windows daily procedure

1. Read `CLAUDE.md`, `AGENTS.md`, the repository map if present, and `NEXT.md`.
2. Run `git status --short`, `git log --oneline -5`, `git worktree list`, and baseline tests.
3. Use one non-main worktree per lane; start with one builder and do not exceed four builders.
4. Measure capacity before increasing concurrency; verify changed paths before reading diffs.
5. Independently rerun tests after the agent exits; never trust the agent's success claim.
6. On failure, record the precise evidence and issue a fresh correction pack; after two failed attempts, split the scoped unit.
7. Record exact commands and worktree paths before session end or context compaction.
8. Require explicit approval before commit, merge, push, deployment, or worktree deletion.
