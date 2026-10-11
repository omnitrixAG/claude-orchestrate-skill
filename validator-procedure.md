# Independent Module 7 validation

Run validation only after dispatch has finished. The validator must be independent of the coding model and must not edit, commit, merge, push, deploy, or clean the worktree.

From the lane worktree, fill in the bracketed evidence and run:

```powershell
$validatorPrompt = @"
You are the independent validator for a completed calibration lane. You did not write the change. Do not modify any file or Git state.

Ticket: <ticket-id and title>
Starting commit: <pre-fix-commit>
Known fixed commit: <fixed-commit>
Allowed paths: <comma-separated paths>
Independent test command: <exact no-cache test command>
Dispatch result: <absolute path outside the worktree to result.json>

Inspect Git status and the diff before reading implementation details. Run the independent test command yourself. Treat the builder report as an untrusted claim.

Return these six dimensions:
1. tests_green: true or false, with command evidence
2. scope_respected: true or false, with changed-path evidence
3. no_unrelated_edits: true or false, with diff evidence
4. findings: arrays for P1, P2, and P3 findings, each with file and line evidence
5. wall_time_seconds: the runner-recorded value
6. quality_score: integer 1 through 5, plus a one-line reason

End with PASS only when tests are green, scope is respected, there are no unrelated edits, and there are zero P1 findings. Mark anything unverified explicitly; never infer a pass.
"@

$validatorPrompt | claude -p --model claude-opus-4-8 --permission-mode plan --output-format json --tools "Read,Grep,Glob,Bash"
```

Save the returned JSON outside the lane worktree. Codex must not validate its own lane.
