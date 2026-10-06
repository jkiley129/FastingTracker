#!/usr/bin/env python3
"""Check that every agent skill has a tier in .claude/settings.json.

`skillOverrides` in the committed .claude/settings.json is the source of
truth for how each skill in .claude/skills/ is exposed to Claude:

  on                   description listed; Claude loads it on its own
  name-only            name listed; Claude uses it when AGENTS.md or the user names it
  user-invocable-only  hidden from Claude; only a person typing /name can run it
  off                  hidden everywhere

A skill missing from skillOverrides silently defaults to "on", which grows
the auto-loaded set and the per-session context cost without anyone deciding
to. This check fails when:

  - an installed skill has no tier (run after `npx skills add` / `update`);
  - a tier names a skill that is neither installed nor a local-only skill in
    .gitignore (a removed or renamed skill left behind);
  - a tier value is not one of the four states.

It warns, without failing, when .claude/settings.local.json overrides a
tier, because that file takes precedence for whoever owns it.

Run directly, or let scripts/install-local-skills.sh run it at the end.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

STATES = {"on", "name-only", "user-invocable-only", "off"}

root = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip())
skills_dir = root / ".claude" / "skills"
settings_path = root / ".claude" / "settings.json"

overrides = json.loads(settings_path.read_text()).get("skillOverrides", {})
installed = {p.parent.name for p in skills_dir.glob("*/SKILL.md")}
local_only = set(re.findall(r"^\.claude/skills/([^/\s]+)/$", (root / ".gitignore").read_text(), re.M))

errors = []
for name in sorted(installed - set(overrides)):
    errors.append(f"{name}: installed but has no tier, so it defaults to \"on\". Add it to skillOverrides.")
for name in sorted(set(overrides) - installed - local_only):
    errors.append(f"{name}: has a tier but is not installed or listed as local-only. Remove the stale entry.")
for name, state in sorted(overrides.items()):
    if state not in STATES:
        errors.append(f"{name}: unknown tier {state!r}; use one of {sorted(STATES)}.")

local_settings = root / ".claude" / "settings.local.json"
if local_settings.exists():
    personal = json.loads(local_settings.read_text()).get("skillOverrides", {})
    for name, state in sorted(personal.items()):
        if overrides.get(name) != state:
            print(f"warning: .claude/settings.local.json sets {name} to {state!r}, overriding the project tier "
                  f"{overrides.get(name, 'on')!r} for you only. The /skills menu writes there.")


def description_chars(skill: str) -> int:
    text = (skills_dir / skill / "SKILL.md").read_text()
    match = re.match(r"^---\n(.*?)\n---", text, re.S)
    front = match.group(1) if match else ""
    desc = re.search(r"^description:\s*(.*?)(?=^[\w-]+:|\Z)", front, re.M | re.S)
    return len(" ".join(desc.group(1).split()).strip(" >|-\"'")) if desc else 0


auto = [name for name, state in overrides.items() if state == "on" and name in installed]
print(f"skills: {len(installed)} installed; tiers: "
      + ", ".join(f"{s} {sum(1 for v in overrides.values() if v == s)}" for s in sorted(STATES)))
print(f"descriptions Claude sees every session (\"on\"): {sum(map(description_chars, auto)):,} characters "
      f"across {len(auto)} skills")

if errors:
    print("\n".join(f"error: {e}" for e in errors), file=sys.stderr)
    sys.exit(1)
