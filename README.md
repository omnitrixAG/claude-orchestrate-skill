# orchestrate

A Claude Code / Claude Agent SDK **skill** that puts a session into orchestrator + quality-gate mode.

When engaged, the session stops being the builder and becomes the conductor: it frames the work as observable acceptance criteria, decomposes it into independently checkable units, drives them tests-first, delegates the building to subagents, then **independently verifies every returned result against evidence** and kicks back anything that misses the bar before it counts as done.

It exists so you don't have to re-type *"use subagents, write the tests first, and you check the work"* on every task.

## Install

Drop the folder into your skills directory:

```bash
git clone https://github.com/cgraves09/claude-orchestrate-skill.git ~/.claude/skills/orchestrate
```

Then invoke it with `/orchestrate`, or let it engage on any task that's more than a trivial edit or a question.

## When to use it

- Starting a feature, landing a bug fix, or doing a refactor
- Any multi-step engineering task worth delegating

## When *not* to

- Conversation and judgment calls
- A single question answerable from context
- A genuinely trivial one- or two-call edit

See [`SKILL.md`](SKILL.md) for the full loop.

## License

Public domain ([The Unlicense](LICENSE)) — do whatever you want with it.
