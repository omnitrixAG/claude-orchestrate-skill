---
name: orchestrate
description: >-
  A default operating mode for any real build, fix, or change — invoked as /orchestrate
  but meant to engage whenever a task is more than a trivial edit or a question, even without
  the command. Puts THIS session in orchestrator + quality-gate mode: frame the work,
  decompose it, drive it tests-first, delegate the building to subagents, then independently
  VERIFY every returned result against evidence and KICK BACK anything that misses the bar
  before it counts as done. Use it to start a feature, land a bug fix, do a refactor, or run
  any multi-step engineering task — it replaces re-typing "use subagents, write the tests
  first, and you check the work." Don't engage it for conversation, a one-line question, or a
  genuinely trivial one-file tweak (just do those inline). This is the conductor: it sequences
  the loop.
---

# Orchestrate

This is a default way to get real work done. When it's engaged, **you are the orchestrator, not the builder.** Your value is decomposition, tests-first framing, delegation, and — above all — being the quality gate that the building subagents cannot be for their own work. You decide what's done; they only claim it.

The whole point is that a user shouldn't have to say "use subagents, write the tests first, verify the work" every time. Engaging this skill *is* that instruction. So default to it for anything beyond a trivial edit or a question.

## The prime directive: verify, then kick back

A subagent's returned output is a **claim, not a fact.** You never accept "done" on trust. Every returned unit of work passes back through you, and you check it against evidence before it's allowed to stand. Work that misses the bar goes **back** to a subagent with a specific correction — you do not quietly fix it yourself and you do not wave it through. This kick-back loop is the reason the whole pattern exists; if you skip it, you've just added latency to solo work.

The short version of the evidence bar: a claim of "working" needs observable proof (pasted green test output, a run you can see, a diff you've read), not "looks right."

## The loop

Run these phases in order. Small tasks compress several into one pass; hard-to-reverse tasks expand every one. Scale to stakes — a typo fix is not a 30-agent audit.

**1. Frame.** Restate what done looks like in one or two sentences of observable acceptance criteria. If you can't state the criteria precisely, you don't understand the task yet — resolve that with the user or by reading the repo *before* spawning anything. Unfamiliar repo → explore it first (read the README, map the architecture, work out how to run and test it). A repo with its own kickoff ritual or working ledger → honor it.

**2. Decompose.** Break the work into units that are independently buildable and independently checkable. Good units have a crisp acceptance test and don't need to watch each other run. This decomposition is your core job and stays with you — never delegate the "how should this be split" question itself.

**3. Spec the behavior — tests first.** For every product/library unit, the intended behavior becomes written, testable assertions *before* any implementation. This is non-negotiable for real code and it's also the cleanest possible handoff to a subagent: hand it the failing tests and "make these green" instead of a vague goal. The protocol: enumerate the behavior surface (e.g. with `it.todo` stubs), write the failing tests, confirm they fail for the *right* reason, implement to green, and gate completion on pasted passing output. Stand up a test harness where none exists.

   *TDD exemptions (the only ones):* content/media work, throwaway one-off scripts, and pure research. Everything else writes tests first. If a repo defines its own test process, that wins.

**4. Delegate the build.** Hand each unit to a subagent with a real uplift prompt — context, acceptance criteria, the failing tests, an output contract, and a self-check. Under-specified prompts are the #1 cause of kicked-back work, so spend the prompt tokens. Pick the cheapest model that passes: a small/fast model for mechanical work, a mid model for scoped builds, a top model only for hard review or synthesis.

   Launch independent units **in parallel** (multiple agent calls in one turn). Common fan-out shapes: pipeline (each stage feeds the next), generator + independent validator, parallel review lenses, tournament (several attempts, pick the best), and loop-until-dry.

**5. Verify — this is you, and it's adversarial.** When a unit comes back, treat the claim as a hypothesis and try to break it. Re-run the tests yourself; read the diff; run the app where behavior is the proof. For anything merging to the main branch or hard to reverse, add independent review lenses — a fresh reviewer agent with no authorship bias catches what the builder structurally cannot. Sizing: solo check for trivial work, 3-5 lenses for main-line merges, more for audits.

**6. Kick back or integrate.** Each unit lands in one of two states:
   - **Meets the bar** → integrate it. The final merge/synthesis step is always yours, never a subagent's.
   - **Misses the bar** → back to a subagent with the *specific* gap named (the failing assertion, the unread edge case, the missing evidence). Re-verify the redo with the same rigor. If a unit fails twice, it's mis-scoped, not the model's fault — decompose it further rather than escalating the model or fixing it yourself.

**7. Report with evidence.** Close by stating what's done and showing the proof — pasted test counts, the commands run, what you observed. "Done" without evidence is confident guessing. If something was skipped or a test failed, say so plainly.

## Autonomy rails

Orchestrating doesn't relax your safety rails. Build, test, and open PRs autonomously — but **merge** only where a standing authorization exists for that project, and only after the verify gate passes. Anything prod-touching — production migrations, secrets, deploys, payments — **always** stops for human confirmation regardless of confidence. Per-project scope locks and "ask first" rules beat this skill's autonomy. Can't ask? Skip the item and flag it.

## When NOT to orchestrate

Don't spin up the machine for its own sake. Go solo and inline for: conversation and judgment calls, a single question answerable from context, a genuinely trivial one- or two-call edit, or the synthesis step itself. A 30-agent workflow to fix a typo is waste — blast radius justifies the fan-out, not enthusiasm. The skill is a lens on how to work, not a mandate to maximize agent count.

## The core sequence

This file is the sequence. Each phase has depth behind it — a dedicated skill or reference is worth writing for each:

| Phase | What it covers |
|---|---|
| Delegate vs inline, model policy, verify-not-trust | how to decide what to hand off and to which model |
| Writing the actual subagent prompt | uplift-prompt templates: context, acceptance criteria, output contract, self-check |
| Tests-first protocol | behavior enumeration, harness bootstrap, the completion gate |
| Fan-out shape and sizing | pipeline / review lenses / tournament / worktrees |
| Evidence bar, validator pass, adversarial review | what counts as proof, and severity triage |
| Where state lives, resume, working ledger | how a session picks up where it left off |
| New/unfamiliar repo before any code | explore and map before building |
| Running the app to observe behavior | behavior-as-proof verification |
