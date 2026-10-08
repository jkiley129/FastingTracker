# Project skills

Agent skills for the iOS app, grouped by domain. This set comes from the
Materia Labs iOS template (`~/Development/iOSProjectTemplate`) and matches
Surveil's. Several domains have more
than one skill on purpose, so the team can compare them over time. When
they disagree, `AGENTS.md` (project conventions) wins, then Apple's
skills on API behavior and availability, then Paul Hudson's skills, then
everything else.

## Tiers

`skillOverrides` in the committed `.claude/settings.json` decides how each
skill is exposed, so every session and every checkout behaves the same.
It is the source of truth; this README describes the policy, not the list.

| Tier | Claude sees | Who starts it | Used for |
|---|---|---|---|
| `on` | Name and description | Claude, when a task matches | One primary skill per domain, plus Apple's SDK 27 skills. Kept small so every description fits the listing budget |
| `name-only` | Name only | Claude, when `AGENTS.md` or the user names it; or you with `/name` | Second opinions, testing, App Intents, build and device tooling, read-only `asc-*` |
| `user-invocable-only` | Nothing | Only a person typing `/name` | Anything that writes to an external system (uploads, submissions, signing, App Store metadata, pricing, ads) and the manual-only merowing skill. Claude Code refuses these when Claude tries |
| `off` | Nothing | Nobody | Unused today |

To change a tier, edit `.claude/settings.json` in a PR. Avoid the `/skills`
menu for this: it writes `.claude/settings.local.json`, which overrides the
project file for you alone and makes your sessions differ from everyone
else's. `scripts/check-skill-tiers.py` fails when an installed skill has no
tier (it would silently default to `on`) or a tier names a skill that no
longer exists, and warns about personal overrides. Run it after
`npx skills add` or `update`; `install-local-skills.sh` runs it last.

Promote a skill to `on` when its domain becomes regular work (App Intents,
App Store Connect reads once `asc` is installed), and demote anything
`/skill-doctor` shows is never used.

Two install paths:

- **Vendored (committed).** MIT skills installed with
  `npx skills add <repo> --skill <name> -a claude-code -y --copy` from the
  repository root and tracked in `skills-lock.json`. Each directory keeps
  `SKILL.md`, `references/` or `reference.md`, any `scripts/` the skill
  runs, and the upstream `LICENSE`; plugin manifests, Codex agent YAML,
  icons, and nested duplicate `SKILL.md` files are removed. Update with
  `npx skills update -p`, then read the diff before committing.
- **Local (gitignored).** Skills whose licenses do not permit
  redistribution. `scripts/install-local-skills.sh` installs them into this
  directory per checkout; run it after cloning and after each Xcode update.
  It refuses to install anything `.gitignore` does not cover. Marked
  *local* below.

## SwiftUI

| Skill | Source | Use |
|---|---|---|
| `swiftui-pro` | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) | `/swiftui-pro [focus]`: the pre-PR review checklist (deprecated API, data flow, navigation, performance, accessibility, hygiene) |
| `swiftui-expert-skill` | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) | Broad SwiftUI guidance verified against Xcode 27, plus Instruments trace recording and analysis (`scripts/`, `xctrace` only) |
| `swiftui-specialist` *local* | Apple, Xcode 27 | `@Observable` invalidation, `ForEach` identity, `@Entry`, animation, localization |
| `swiftui-whats-new-27` *local* | Apple, Xcode 27 | SDK 27 API changes; read before using anything new in iOS 27 (gate with `#available` while the target is iOS 26) |
| `swiftui-ui-patterns`, `swiftui-view-refactor`, `swiftui-performance-audit` *local* | OpenAI Build iOS Apps | Navigation and sheet patterns, view extraction, invalidation and layout-thrash audits |
| `swiftui-iphone-duo` | [FloWritesCode/fwc-swiftui-skills](https://github.com/FloWritesCode/fwc-swiftui-skills) | iPhone Duo adaptive layout, tiered so universal adaptivity comes first |
| `swiftui-liquid-glass` | FloWritesCode/fwc-swiftui-skills | iOS 26+ Liquid Glass APIs and pitfalls |
| `swiftui-liquid-glass-openai` *local* | OpenAI Build iOS Apps | OpenAI's Liquid Glass skill, renamed because it collides with the FloWritesCode one |
| `building-document-based-swiftui-applications` *local* | Apple, Xcode 27 | `Document` / `DocumentGroup` apps |

## Swift and concurrency

| Skill | Source | Use |
|---|---|---|
| `swift-concurrency-pro` | [twostraws/Swift-Concurrency-Agent-Skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill) | `/swift-concurrency-pro [focus]`: the pre-PR concurrency checklist |
| `swift-concurrency` | [AvdLee/Swift-Concurrency-Agent-Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill) | Actors, `Sendable`, data-race safety; use for the Swift 6 language-mode migration |
| `merowing-swift-engineering` *local, manual only* | [merowing.info general.md](https://merowing.info/posts/stop-getting-average-code-from-your-llm/) | `/merowing-swift-engineering`: Krzysztof Zabłocki's architecture-first review lens. Never auto-invoked: it is written to apply to every Swift query and to ask clarifying questions first. His `rule-loading.md` is not installed; it routes to paid rule files |
| `adopt-c-bounds-safety` *local* | Apple, Xcode 27 | C `-fbounds-safety`, for C code only |

## Persistence

| Skill | Source | Use |
|---|---|---|
| `swiftdata-pro` | [twostraws/SwiftData-Agent-Skill](https://github.com/twostraws/SwiftData-Agent-Skill) | SwiftData models, queries, migrations, and CloudKit sync rules |
| `core-data-expert` | [AvdLee/Core-Data-Agent-Skill](https://github.com/AvdLee/Core-Data-Agent-Skill) | Core Data stacks and migrations; with SwiftData, mostly for store-level debugging |

## Testing

Tests use Swift Testing (`AGENTS.md`); `swift-testing-pro` is the default.
An app that still has XCTest tests keeps one framework per suite: convert
in a PR of its own, never mixed into unrelated changes.

| Skill | Source | Use |
|---|---|---|
| `swift-testing-pro` | [twostraws/Swift-Testing-Agent-Skill](https://github.com/twostraws/Swift-Testing-Agent-Skill) | Swift Testing macros, parameterized tests, XCTest migration |
| `swift-testing-expert` | [AvdLee/Swift-Testing-Agent-Skill](https://github.com/AvdLee/Swift-Testing-Agent-Skill) | Same domain, AvdLee's take |
| `modernize-tests` *local* | Apple, Xcode 27 | Apple's XCTest-to-Swift-Testing migration guidance |

## Build, debugging, and device

| Skill | Source | Use |
|---|---|---|
| `xcode-build-orchestrator`, `xcode-build-benchmark`, `xcode-project-analyzer`, `xcode-compilation-analyzer`, `spm-build-analysis`, `xcode-build-fixer` | [AvdLee/Xcode-Build-Optimization-Agent-Skill](https://github.com/AvdLee/Xcode-Build-Optimization-Agent-Skill) | `/xcode-build-orchestrator`: benchmark, audit, approval-gated fixes. Build-setting fixes go in `project.yml`, never the generated pbxproj |
| `audit-xcode-security-settings` *local* | Apple, Xcode 27 | Security-oriented build settings and analyzer checks; changes go in `project.yml` |
| `ios-ettrace-performance`, `ios-memgraph-leaks` *local* | OpenAI Build iOS Apps | ETTrace flamegraphs (needs `brew install emergetools/homebrew-tap/ettrace`), simulator memgraph leak triage |
| `ios-simulator-browser` *local* | OpenAI Build iOS Apps | Renders SwiftUI previews in a scratch app in the simulator; builds in a temp directory, never touches our project |
| `device-interaction` *local* | Apple, Xcode 27 | Screenshot/tap verification through Xcode MCP tools; needs the Xcode MCP server configured |
| `ios-debugger-agent` *local* | OpenAI Build iOS Apps | Build/run/debug through XcodeBuildMCP; needs that MCP server configured |
| `uikit-app-modernization` *local* | Apple, Xcode 27 | Multi-window UIKit modernization, for UIKit code |

## App Intents

| Skill | Source | Use |
|---|---|---|
| `app-intents-specialist`, `app-intents-whats-new-27` *local* | Apple, Xcode 27 | App Intents best practices and iOS 26/27 changes |
| `ios-app-intents` *local* | OpenAI Build iOS Apps | Siri, Shortcuts, and widget intent wiring |

## App Store Connect

[rorkai/app-store-connect-cli-skills](https://github.com/rorkai/app-store-connect-cli-skills), 25 `asc-*` skills. They drive the
[`asc` CLI](https://github.com/rorkai/App-Store-Connect-CLI), which must be installed and authenticated separately.

TestFlight uploads and App Store submissions follow the release path in
`CLAUDE.md` (Releases). The skills that build, upload, sign or submit
(`asc-xcode-build`, `asc-testflight-orchestration`, `asc-release-flow`,
`asc-build-lifecycle`, `asc-wall-submit`, `asc-ad-hoc-distribution`,
`asc-signing-setup`) are `user-invocable-only`: a person runs them, Claude
never does. Read-only work (analytics, crash
triage, submission health, ID lookup, ASO audit) is fine. Anything that
writes to App Store Connect (metadata, localization, pricing, screenshots,
subscriptions) needs the owner's explicit go-ahead for that change.
`asc-notarization`, `asc-revenuecat-catalog-sync`, and `asc-apple-ads`
cover surfaces most of our apps do not use.

## Cost

Every `on` skill's description sits in context for every session in this
repository, and `name-only` skills add their names. With the current tiers
that is about 3K characters of descriptions across 8 skills (all 61 at
`on` would be about 21K).
Claude Code's listing budget defaults to 1% of the context window; past
it, descriptions are dropped starting with the least-used skills, which
silently stops them from loading on their own. `check-skill-tiers.py`
prints the current total. In a session, `/context` shows the listing size
the model actually receives and `/skill-doctor` (Claude Code v2.1.252+)
shows each skill's cost and how often it is used.
