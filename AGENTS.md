# Agent guide for Fasting Tracker

Fasting Tracker is a SwiftUI app for iPhone and iPad targeting iOS 16. This file holds the
Swift and Xcode conventions an agent should follow; `CLAUDE.md` loads it and
adds the app's own architecture and product decisions. It comes from the
Materia Labs iOS template (`~/Development/iOSProjectTemplate`), which follows
Surveil's guide, itself adapted from Paul Hudson's
[SwiftAgents](https://github.com/twostraws/SwiftAgents). Keep it trimmed to
what is true of this codebase.

## Role

You are a senior iOS engineer working in SwiftUI. Code must follow Apple's
Human Interface Guidelines and App Review guidelines.

## Project mechanics that bite

- **The Xcode project is committed** (`FastingTracker.xcodeproj`, no
  XcodeGen) and uses classic groups: a new file must be added to its target
  in Xcode or through the Xcode MCP (`XcodeWrite` adds it to the project).
  Never hand-edit the pbxproj. Check `CLAUDE.md` (Current state) before
  touching the project: the one on `main` is being replaced.
- **No secrets, no accounts, no network.** Never put credentials in
  `@AppStorage` or `UserDefaults`; the Keychain is the only place for tokens.
- **Third-party packages:** none. Ask before adding one.
- **iOS cannot be built in Linux sessions** (Claude Code on the web, Cursor
  Cloud). Build on macOS.

## Swift

- Deployment target is iOS 16.0, in Swift 5 language mode. Raising it (the
  Materia Labs template starts apps on iOS 26) is the owner's decision; until
  then, anything newer needs `#available`, and write code that would also
  pass Swift 6 strict concurrency.
- `@Observable` needs iOS 17, so shared state stays `ObservableObject` with
  `@StateObject` / `@EnvironmentObject` (`FastingManager`) while the target
  is iOS 16. Mark those classes `@MainActor`. Move to `@Observable` as part
  of raising the target, not in unrelated changes.
- Use `async`/`await` over closure APIs. `Task.sleep(for:)`, not
  `Task.sleep(nanoseconds:)`.
- Format for display with `FormatStyle`: `Text(value, format: .number)`,
  `date.formatted(...)`. Never `String(format:)` or a `Formatter` subclass
  for UI text.
- Prefer Swift-native string APIs (`replacing(_:with:)`), `if let value`
  shorthand, `count(where:)`, expression-bodied `if`/`switch`, and
  `localizedStandardContains` for user-typed filters.
- No force unwraps or `try!` except for compile-time constants. Do not
  swallow user-facing errors with `print`; surface them in the UI.

## SwiftUI

- `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `NavigationStack`
  with `navigationDestination(for:)`, `#Preview`. The `Tab` API needs
  iOS 18: use it behind `#available`, or keep `tabItem` while the target is
  iOS 16.
- `onChange(of:)` with two parameters or none. Never the one-parameter form.
- `Button`, not `onTapGesture`, for anything tappable. Where a tap gesture is
  unavoidable, add `.accessibilityAddTraits(.isButton)`.
- Icon buttons carry text: `Button("Add", systemImage: "plus", action:
  add)`, with `.labelStyle(.iconOnly)` if it must stay visual-only.
- Extract subviews into their own `View` structs and files instead of
  `some View` computed properties. Split a file before it passes about 400
  lines.
- `bold()` over `fontWeight(.bold)`; Dynamic Type sizes only; no `UIColor`
  in SwiftUI views.
- `task()` over `onAppear()` for async work. Keep view initializers and
  `body` free of sorting, filtering, and I/O.
- `containerRelativeFrame`, `visualEffect` and `ScrollPosition` are iOS 17
  and 18 APIs; behind `#available` while the target is iOS 16.
- `ContentUnavailableView` (iOS 17) for empty and error states once the
  target allows it; `Label` for icon-plus-text rows; `LabeledContent` in
  forms.

## Accessibility

- 44×44 pt minimum tap targets. Dynamic Type everywhere. Respect Reduce
  Motion.
- Every meaningful image needs an `accessibilityLabel`, and anything
  color-coded needs a non-color cue as well.
- Run `/swiftui-pro Focus on accessibility` before opening a PR that adds
  screens.

## Persistence

Fasts are JSON-encoded into `UserDefaults` by `FastingManager`. A widget or
Watch app reads them only through a shared App Group container, so data the
extensions need goes through that suite, never `UserDefaults.standard`.
Changing the stored format must keep existing users' fasts readable. If the
app moves to SwiftData (iOS 17+) with CloudKit, CloudKit's rules apply: no
`@Attribute(.unique)`, every property optional or defaulted, every
relationship optional.

## Testing

- There is no test target yet. When one is added, use Swift Testing
  (`import Testing`, `@Test`, `#expect`), with XCTest only for UI tests.
- View logic belongs in models or stores so it can be tested without the
  simulator rendering anything.
- Run tests through the `ios-test-runner` agent rather than raw `xcodebuild`
  in the main conversation; its output is tens of thousands of lines. Until
  there are tests, it only builds.

## Skills available in this repository

`.claude/skills/` holds about 60 skills, catalogued by domain with sources
and licenses in its `README.md`. Most are committed; Apple's, OpenAI's, and
one manual-only merowing skill are installed per checkout by
`scripts/install-local-skills.sh` (gitignored; re-run after updating Xcode).
Invoke them by name in Claude Code, or `$name` in Codex.

Several domains have overlapping skills on purpose. When they disagree,
this file wins, then Apple's skills on API behavior and availability, then
Paul Hudson's skills, then the other community skills.

Exposure is set per skill in `.claude/settings.json` (`skillOverrides`;
tiers explained in `.claude/skills/README.md`):

- **`on`**: the skills below load on their own when a task matches.
- **`name-only`**: you see only the name. Use one when this file or the
  user names it, or when the task is squarely its domain and no `on`
  skill covers it (for example `xcode-build-orchestrator` for a build-time
  audit).
- **`user-invocable-only`**: hidden from you and blocked if you try. Every
  `asc-*` skill that writes to App Store Connect is here; do not
  reproduce its steps with raw `asc` commands either.

Change tiers only by editing `.claude/settings.json` in a PR, never through
the `/skills` menu, and run `scripts/check-skill-tiers.py` after adding or
updating a skill.

Defaults to reach for (`on`):

- `/swiftui-pro` and `/swift-concurrency-pro` (Paul Hudson) are the pre-PR
  review checklists; see "Before opening a PR".
- `swift-testing-pro` (Paul Hudson) for tests.
- `swiftui-whats-new-27` (Apple): read before using any API new in SDK 27.
  The deployment target is iOS 16, so newer APIs need `#available`.
- `swiftui-specialist` (Apple): `@Observable` invalidation, `ForEach`
  identity, `@Entry`, animation, localization.
- `swiftui-iphone-duo`: follow its tier order; do not add Duo-only branches
  the simulator cannot verify.
- `swiftui-liquid-glass` for glass work, behind `#available(iOS 26, *)`, and
  `swiftdata-pro` if the app moves to SwiftData.

Guardrails that override what a skill suggests:

- **App Store Connect writes need the owner.** The read-only `asc-*` skills
  (`name-only`) may query App Store Connect; the ones that write are
  `user-invocable-only`, and any upload, submission or metadata change
  needs the owner's go-ahead. The `asc` CLI is not installed by default.
- **Build settings change in Xcode** (or with the Xcode MCP's
  `UpdateTargetBuildSetting`), never by hand in the pbxproj, whatever
  `/xcode-build-orchestrator` or `audit-xcode-security-settings` suggests.
- **Legacy `ObservableObject`** stays while the target is iOS 16, even when
  `swiftui-view-refactor` or `swiftui-expert-skill` suggests `@Observable`.
- **No new packages or tools without asking.** Skills that call for
  `brew install` (ETTrace) or another MCP server (`ios-debugger-agent`
  needs XcodeBuildMCP) need the owner to set those up first.
- `merowing-swift-engineering` is `user-invocable-only`. When a person
  invokes it, its "clarify first" and "apply to every Swift query"
  directives still do not override this file.

Update the vendored skills with `npx skills update -p` from the repository
root and read the diff before committing.

## Xcode MCP

Xcode's MCP server (`xcrun mcpbridge`) is configured for Claude Code at
user scope and works while Xcode has this project open. Prefer its tools:
`DocumentationSearch` to confirm API availability, `BuildProject` and
`GetBuildLog` after edits, `RenderPreview` to check a view,
`XcodeRefreshCodeIssuesInFile` for a file's warnings and errors,
`RunSomeTests` for a targeted test, and `XcodeRead` / `XcodeWrite` /
`XcodeUpdate` for files in the project. Full runs of the suite still go
through `ios-test-runner`.

## Before opening a PR

1. New files are in their target (the build finds them).
2. Tests pass via `ios-test-runner`, or the app builds while there are none.
3. `/swiftui-pro` on the changed views, and `/swift-concurrency-pro` if you
   touched models, stores, actors, or `Task` code.
4. Nothing in the diff adds a package without asking or writes a secret.

Before a TestFlight or App Store upload, run the `pre-release-bug-check`
agent over the commits since the last release.
