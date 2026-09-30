# claude-orchestrate-skill

A set of Claude Code skills and agents that put a session into orchestrator and quality-gate mode. When engaged, the session stops being the builder and becomes the conductor: it frames the work as observable acceptance criteria, decomposes it into independently checkable units, drives them tests-first, delegates the building to subagents, and independently verifies every returned result before it counts as done. It exists so you do not have to re-type "use subagents, write the tests first, and check the work" on every task.

## Install

**Option 1: clone and run the installer**

```bash
git clone https://github.com/cgraves09/claude-orchestrate-skill.git && cd claude-orchestrate-skill && ./install.sh
```

This copies every skill into `~/.claude/skills/` and every agent into `~/.claude/agents/`. Run it again any time to pick up updates; it will not overwrite a file you have edited locally unless you pass `--force`.

**Option 2: paste a prompt to Claude Code**

Tell Claude Code to clone this repo and run its installer, and it will set the whole set up for you in one turn. The ready-to-paste prompt, with a copy button, is at [ducktate.com/prompts/orchestrate](https://ducktate.com/prompts/orchestrate/). The short version is: "Clone https://github.com/cgraves09/claude-orchestrate-skill.git and run ./install.sh."

## What you get

**Skills** (`skills/*/SKILL.md`)

| Skill | Purpose |
|---|---|
| `orchestrate` | Entry point: puts the session in orchestrator and quality-gate mode for any real build, fix, or change. |
| `orchestrator-delegation` | Decide whether to work inline or delegate, pick the model, write subagent definitions, and check delegated output. |
| `delegate-prompts` | The five-element uplift anatomy and copy-adaptable templates for writing a strong subagent dispatch prompt. |
| `tdd-protocol` | Tests-first protocol: enumerate the behavior, write failing tests, confirm they fail for the right reason, then implement to green. |
| `workflow-patterns` | Catalog of multi-agent shapes (fan-out, pipeline, generator and validator, tournament, and more) and how to size them to the stakes. |
| `validation-and-evidence` | The evidence standard for "done," the independent validator pass, and adversarial review patterns. |
| `context-and-state` | Where state lives (a per-repo NEXT.md ledger plus your tracker and notes) and the protocol for resuming after an interrupt. |
| `familiarize` | First-contact exploration of an unfamiliar repo: architecture, stack, how to run and test it, and a generated repo map. |

**Agents** (`agents/*.md`)

| Agent | Purpose |
|---|---|
| `implementer` | Scoped executor that builds one delegated task to its tests and reports a diff summary plus verbatim test output. |
| `researcher` | Evidence gatherer that answers a specific question with cited findings, each labeled VERIFIED, INFERRED, or UNKNOWN. |
| `validator` | Independent adversarial verifier that checks completed work against acceptance criteria and reports, never fixes. |
| `ops` | Runs the git, gh and tracker chores a dispatch lists, stops on any failure, writes no product code. |
| `visual-check` | Takes or opens screenshots and returns a text verdict, so images stay out of the orchestrator's context. |

Every agent lists only the tools it needs. An agent without a `tools:` line loads every tool's description and the skill list into each call, which costs several times more context.

## How it fits together

`orchestrate` is the entry point. It is the skill you invoke (with `/orchestrate`) or that engages automatically on any task bigger than a trivial edit, and it sequences the whole loop: frame, spec the behavior, delegate, verify.

The other skills are not invoked directly; `orchestrate` loads them by phase as the work reaches that phase:

- Deciding **whether and how to delegate** a unit of work pulls in `orchestrator-delegation`.
- Writing the **actual dispatch prompt** for a subagent pulls in `delegate-prompts`.
- Specifying behavior **before writing code** pulls in `tdd-protocol`.
- Picking the **shape** of a multi-agent fan-out pulls in `workflow-patterns`.
- Judging whether returned work is **actually done** pulls in `validation-and-evidence`.
- Starting or resuming work with **prior state** pulls in `context-and-state`.
- Landing in a **repo you have never seen** pulls in `familiarize` first, before any of the above.

The five agents are the standing subagent definitions that `orchestrator-delegation` dispatches work to: `implementer` builds, `researcher` gathers evidence, `validator` checks, `ops` runs repo chores, `visual-check` looks at screenshots.

## Try it

Give Claude Code a real task and let `orchestrate` run the loop:

```
/orchestrate Add input validation to the signup form and cover it with tests.
```

Claude Code will frame the acceptance criteria, spec the behavior as failing tests, delegate the build to a subagent, and independently verify the result before calling it done.

## Uninstall

```bash
rm -rf ~/.claude/skills/{orchestrate,orchestrator-delegation,delegate-prompts,tdd-protocol,workflow-patterns,validation-and-evidence,context-and-state,familiarize}
rm -f ~/.claude/agents/{implementer,researcher,validator,ops,visual-check}.md
```

## License

Public domain ([The Unlicense](LICENSE)). Do whatever you want with it.
