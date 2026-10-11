# Goal

Fix `<ticket-id>: <ticket-title>` so the supplied regression test passes without changing unrelated behavior.

# Measured facts

- Repository: `<repository-name>`.
- Starting commit: `<known-pre-fix-commit>`.
- Known fixed commit, retained only as comparison evidence: `<known-fixed-commit>`.
- The regression test has been observed red at the starting commit and green at the known fixed commit: `<evidence-path-or-command>`.
- Record only measurements actually observed; do not invent test, coverage, performance, or timing results.

# Task and exact file scope

Implement the smallest correct fix for the ticket.

Allowed paths:

- `<implementation-path>`
- `<additional-allowed-path-if-required>`

Acceptance criteria:

- AC1: `<behavioral requirement>`.
- AC2: `<regression requirement>`.
- AC3: `<compatibility-or-edge-case requirement>`.
- AC4: `<focused-test-command>` passes.
- AC5: only the listed paths change; no generated, cache, credential, network, or production artifacts are added.

# Runner responsibilities

The runner records the backend, model, starting commit, lane identifier, wall time, changed paths, scope result, independent test result, errors, and limitations. It runs the focused test after the agent exits and keeps logs outside the worktree. The agent's own success claim is not verification.

# Repository rules

1. Work only inside the supplied clean, non-main worktree.
2. Do not switch, create, delete, commit, merge, push, deploy, or clean up branches or worktrees.
3. Do not access production systems, credentials, secrets, external services, or the network.
4. Do not edit outside the allowed paths.
5. Stop and report ambiguity instead of guessing.
6. Finish with changed paths, `git diff --stat`, `git status --short`, and the focused-test output.
