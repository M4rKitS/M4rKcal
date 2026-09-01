# M4rkcal

A native iOS app for tracking daily calorie and protein intake, built with SwiftUI and SwiftData. Designed around a simple principle: know your numbers without the friction.

## Features

- **Daily dashboard** with animated progress rings for calories and protein, adjustable against a configurable goal range
- **Apple Watch integration** via HealthKit — active and basal calories, deduplicated across sources, with a research-based adjustment applied to active calorie estimates
- **Barcode scanning** using VisionKit, pulling live nutrition data from Open Food Facts
- **Favorites & recents** for fast, repeatable meal logging without retyping the same foods
- **Body tracking** — weight and four body measurements on a biweekly cycle, with local reminder notifications
- **History view** — weekly/monthly summaries, interactive deficit charts, and weight/measurement trends over time
- **Workout integration** via the Hevy API, showing today's training volume alongside nutrition data
- **Local-first storage** with SwiftData — no account, no cloud dependency, all data stays on-device

## Tech Stack

- **SwiftUI** + **SwiftData** (MVVM architecture)
- **HealthKit** — Apple Watch calorie data with source-based deduplication
- **VisionKit** — barcode scanning
- **Swift Charts** — interactive history visualizations
- **Keychain** — secure local storage of API credentials
- Open Food Facts API, Hevy API

## Design

Dark-first interface with a custom terracotta accent, built around the same visual language as [M4rKitS.dev](https://m4rkits.dev). Category-coded meal icons, Apple Watch-style activity rings, and an animated launch screen.

## Requirements

- iOS 17+
- Xcode 15+
- An Apple Developer account (free tier works for local builds)
- Optional: a Hevy Pro account for workout sync

## Setup

1. Clone the repo
2. Open `M4rkcal.xcodeproj` in Xcode
3. Set your own signing team under project settings
4. Build and run on a physical device (HealthKit features require a real device, not the simulator)

## About

Built by [Marcos Rodríguez](https://m4rkits.dev) as a personal project to solve a real day-to-day need — and as a demonstration of native iOS development within the M4rKitS.dev portfolio.
