#!/usr/bin/env bash
# Repo self-check. Exit 1 on any failure. Run: scripts/check.sh
set -u
cd "$(dirname "$0")/.."
fail=0; pass=0
ok(){ pass=$((pass+1)); echo "PASS  $1"; }
bad(){ fail=$((fail+1)); echo "FAIL  $1"; }

SKILLS="orchestrate orchestrator-delegation delegate-prompts tdd-protocol workflow-patterns validation-and-evidence context-and-state familiarize"
AGENTS="implementer researcher validator"
EXCLUDED='memory-hub|linear-ops|documentation-discipline|autonomous-loops|research-first|visual-planner|interview-mode'
PRIVATE='[Cc]hris\b|mem0|hub\.env|[Jj]abster|~/base|[Oo]bsidian|cozmos|Donna|christophergraves|[Gg]ravitas|[Dd]ucktate|[Rr]ubberduck|\bLinear\b|\bvault\b|BOX/|COZ/|openclaw|2026-0[0-9]-[0-9][0-9]'

# 1. layout
for s in $SKILLS; do [ -f "skills/$s/SKILL.md" ] && ok "skills/$s/SKILL.md exists" || bad "skills/$s/SKILL.md missing"; done
for a in $AGENTS; do [ -f "agents/$a.md" ] && ok "agents/$a.md exists" || bad "agents/$a.md missing"; done
[ -f install.sh ] && ok "install.sh exists" || bad "install.sh missing"
[ -f README.md ] && ok "README.md exists" || bad "README.md missing"
[ -f SKILL.md ] && bad "top-level SKILL.md still present (must live under skills/orchestrate/)" || ok "no stray top-level SKILL.md"

# 2. frontmatter
for s in $SKILLS; do f="skills/$s/SKILL.md"; [ -f "$f" ] || continue
  head -1 "$f" | grep -q '^---$' && sed -n '2,12p' "$f" | grep -q "^name: $s$" && ok "$s: frontmatter name matches dir" || bad "$s: frontmatter name missing or wrong"
  sed -n '2,20p' "$f" | grep -q '^description:' && ok "$s: has description" || bad "$s: no description"; done
for a in $AGENTS; do f="agents/$a.md"; [ -f "$f" ] || continue
  sed -n '2,15p' "$f" | grep -q "^name: $a$" && ok "$a: agent name" || bad "$a: agent name missing"
  sed -n '2,20p' "$f" | grep -qE '^model: (sonnet|opus|haiku)$' && ok "$a: model is an alias (sonnet/opus/haiku)" || bad "$a: model must be a plain alias, not a dated model id"; done

# 3. no private references anywhere in shipped text
# The one deliberate product link: the README points at the page that hosts the install prompt.
hits=$(grep -rnE "$PRIVATE" --include='*.md' --include='*.sh' . | grep -v '^./scripts/check.sh' | grep -v '^./.git/' | grep -v 'https://ducktate.com/prompts/orchestrate/')
[ -z "$hits" ] && ok "no private references" || { bad "private references found:"; echo "$hits" | head -40; }

# 4. no references to skills that are not shipped
ex=$(grep -rnE "\b($EXCLUDED)\b" --include='*.md' . | grep -v '^./scripts/' | grep -v '^./.git/')
[ -z "$ex" ] && ok "no references to unshipped skills" || { bad "references to unshipped skills:"; echo "$ex" | head -40; }

# 5. every shipped skill that is referenced exists (sanity on the closure)
for s in $SKILLS; do grep -rqE "\b$s\b" --include='*.md' skills agents README.md 2>/dev/null && ok "$s is referenced somewhere" || bad "$s is never referenced"; done

# 6. install.sh: syntax + dry run into a temp HOME
if [ -f install.sh ]; then
  bash -n install.sh && ok "install.sh parses" || bad "install.sh syntax error"
  T=$(mktemp -d); HOME="$T" bash install.sh >"$T/out.log" 2>&1; rc=$?
  [ $rc -eq 0 ] && ok "install.sh exits 0 in a fresh HOME" || { bad "install.sh exit $rc"; cat "$T/out.log"; }
  n=0; for s in $SKILLS; do [ -f "$T/.claude/skills/$s/SKILL.md" ] && n=$((n+1)); done
  [ $n -eq 8 ] && ok "install.sh placed all 8 skills" || bad "install.sh placed $n/8 skills"
  m=0; for a in $AGENTS; do [ -f "$T/.claude/agents/$a.md" ] && m=$((m+1)); done
  [ $m -eq 3 ] && ok "install.sh placed all 3 agents" || bad "install.sh placed $m/3 agents"
  # second run must not clobber a locally-edited file without --force
  echo "local edit" >> "$T/.claude/skills/orchestrate/SKILL.md"
  HOME="$T" bash install.sh >"$T/out2.log" 2>&1
  grep -q "local edit" "$T/.claude/skills/orchestrate/SKILL.md" && ok "install.sh keeps an existing edited file (no --force)" || bad "install.sh overwrote an edited file without --force"
  HOME="$T" bash install.sh --force >"$T/out3.log" 2>&1
  grep -q "local edit" "$T/.claude/skills/orchestrate/SKILL.md" && bad "install.sh --force did not overwrite" || ok "install.sh --force overwrites"
  # symlinked destinations must never be followed (no write outside HOME), with or without --force
  O=$(mktemp -d); mkdir -p "$T/.claude/skills/orchestrate" "$T/.claude/agents"
  ln -sf "$O/escaped.md" "$T/.claude/skills/orchestrate/SKILL.md"
  echo "precious" > "$O/precious.md"; ln -sf "$O/precious.md" "$T/.claude/agents/validator.md"
  HOME="$T" bash install.sh >"$T/out4.log" 2>&1; HOME="$T" bash install.sh --force >"$T/out5.log" 2>&1
  [ ! -e "$O/escaped.md" ] && ok "install.sh does not write through a dangling symlink" || bad "install.sh wrote through a dangling symlink"
  [ "$(cat "$O/precious.md")" = "precious" ] && ok "install.sh --force does not overwrite through a symlink" || bad "install.sh --force overwrote a file outside HOME via symlink"
  grep -q "symlink" "$T/out4.log" && ok "install.sh reports the skipped symlink" || bad "install.sh silent about the symlink"
  # summary must count files actually written; a second identical run writes nothing
  HOME="$T" bash install.sh --force >/dev/null 2>&1; rm -f "$T/.claude/skills/orchestrate/SKILL.md" "$T/.claude/agents/validator.md"; HOME="$T" bash install.sh --force >/dev/null 2>&1
  HOME="$T" bash install.sh >"$T/out6.log" 2>&1
  grep -q "Installed 0 skills and 0 agents" "$T/out6.log" && ok "install.sh summary counts only files written (identical rerun = 0)" || { bad "install.sh summary over-reports on an identical rerun"; tail -1 "$T/out6.log"; }
  rm -rf "$T" "$O"
fi

echo; echo "$pass passed, $fail failed"; [ $fail -eq 0 ]
