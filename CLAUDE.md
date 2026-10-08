@AGENTS.md

# Fasting Tracker

## What this is
A simple intermittent-fasting tracker, inspired by Zero: start and end a
fast, watch a live timer and a progress ring toward the goal, and look back
at past fasts. See `README.md`.

## Current state (October 2026)
- `main` holds only the first commit (January 2026): the app, its model and
  `FastingManager`. Its `project.pbxproj` does not open in Xcode 27 ("the
  project is damaged"); do not try to repair it by hand.
- Work from January that is not committed yet replaces that project file and
  adds a home-screen widget extension, a Watch app, a shared data manager
  and an App Group. Build on it, or
  restart the project from the Materia Labs template
  (`~/Development/iOSProjectTemplate`); either is the owner's decision.
- The bundle ID is still a placeholder (`com.yourname.FastingTracker`) and
  no team is set. Materia Labs apps use `com.materia-labs.<app>`.

## Key decisions
- **No accounts, no network.** Fasts stay on the device (and in the App
  Group shared with the widget and Watch app).

## Releases
Not released. Run the `pre-release-bug-check` agent before the first
TestFlight or App Store upload.
