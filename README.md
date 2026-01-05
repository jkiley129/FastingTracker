# Fasting Tracker

A simple iOS app for tracking intermittent fasting, inspired by Zero.

## Features

- Start and end fasting periods
- Track fasting duration with a live timer
- Visual progress ring showing progress toward your goal
- Fasting history
- Persistent data storage with UserDefaults

## Tech Stack

- SwiftUI
- iOS 16+
- MVVM Architecture

## Getting Started

1. Open `FastingTracker.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (Cmd+R)

## Project Structure

- `FastingTrackerApp.swift` - App entry point
- `ContentView.swift` - Main UI with timer and controls
- `Models/`
  - `Fast.swift` - Fast data model
  - `FastingManager.swift` - Business logic and data persistence
