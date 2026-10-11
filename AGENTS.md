# Codex orchestration repository

<!-- REPOSITORY_CODEX_DISCOVERY_MARKER: B91C-REPO-ORCH-20261010 -->

This repository is used to learn, test, and calibrate reusable orchestration patterns.

## Working rules

- Treat this repository as a learning and validation fixture.
- Keep changes focused on orchestration, skills, agents, scripts, and documentation.
- Do not modify the user's global Codex configuration from inside this repository.
- Do not access production systems or external services unless explicitly approved.
- Preserve existing skills and agent definitions.
- Prefer read-only discovery tests before implementation tests.
- Report commands, files changed, test results, and unknowns clearly.
- Never treat an agent's success claim as verification; rerun scoped tests independently.
- Commit, merge, push, deployment, and worktree deletion require explicit approval.

## Safe orchestration test

A discovery test must:

1. Confirm that global instructions were loaded.
2. Confirm that repository instructions were loaded.
3. Quote the requested verification markers.
4. Make no repository changes.
5. Leave the working tree clean.

## Instruction synchronization

`CLAUDE.md` is the canonical repository guidance. `AGENTS.md` is a regular-file mirror for Windows compatibility and must remain byte-for-byte identical.

Read-only drift check from the repository root:

```powershell
if ((Get-FileHash -Algorithm SHA256 .\CLAUDE.md).Hash -ne (Get-FileHash -Algorithm SHA256 .\AGENTS.md).Hash) { throw 'CLAUDE.md and AGENTS.md have drifted.' }
```
