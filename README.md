# Tabletop Ledger

A local-first SwiftUI iPhone app inspired by the original illustrated mockup. No third-party dependencies or app account required. Minimum target: iOS 17.

## Open and run

1. Open `GameJournal.xcodeproj` in Xcode.
2. Select the **GameJournal** scheme and an installed iPhone simulator, then Run.
3. For a physical iPhone, choose your Apple development team in Signing & Capabilities and use a unique bundle identifier if needed. Use your own Apple development team for device builds.

## Implemented

- Illustrated forest-and-sun header, warm cream/forest palette, SF Symbols, terracotta action button.
- Session history and personal statistics.
- Manual game title, date, reusable internal players, optional scores, multiple winner selection (including no recorded winner), optional single session rating, notes.
- Read-only session detail screens with an Edit action. Unsaved changes are discarded only after confirmation.
- Optional photo-library selection and camera capture. Images are resized to a maximum 1600 pixels and JPEG-encoded, stripping source metadata. Camera permission is requested only when you tap Take photo.
- Player profiles and histories, multiple-winner-aware win rates, and head-to-head counts.
- Local atomic JSON persistence, including photo data. No network upload, accounts, or analytics. New players are added to the internal list only when their session is saved.

## Statistics

Every selected winner receives one win. Win-rate denominators include only sessions in which the player participated and at least one winner was recorded. No-winner sessions count as games played but not toward win rate. Shared wins are excluded from head-to-head win/loss counts. This first version does not track team assignments, so head-to-head is based on recorded outcomes rather than inferred teams.

## Verification

- Xcode Debug iPhone Simulator builds and model regression tests pass. Simulator resources use local ad-hoc signing.
- Foundation tests passed: ties/multiple winners, losses, no-result exclusion, zero denominator, Codable round-trip, photo-byte round-trip, atomic disk write/read.
- Run core tests: `swiftc GameJournal/Models.swift Tests/main.swift -o /tmp/gamejournal-tests && /tmp/gamejournal-tests`.
- Simulator launch verified on iPhone 18 Pro / iOS 27.2: installed, launched, and visually checked the rendered home screen. The earlier CoreSimulator version mismatch is no longer blocking launch. Session detail/edit navigation, saving, cancellation, and launch animation have been checked in the simulator. Broader device testing remains pending.

## Intentionally not done yet

- iCloud syncing, a backend, user accounts, game lookup/autofill, team management, monetization.
- Public App Store release and privacy-policy/support pages. TestFlight distribution setup is in progress.
- End-to-end device validation of camera, Photos picker, keyboard behavior, accessibility/Dynamic Type, and relaunch persistence.
- Session deletion/export and player merging. Existing records can be edited.

This is a compiling first implementation, not an App Store-ready release. Session photos are stored locally; the optional iCloud sync discussed in planning has not been enabled.

## Tabletop Ledger branding
The display name is Tabletop Ledger; the existing `app.luis.GameJournal` bundle identifier and `game-journal-v1.json` storage remain unchanged. The Xcode scheme is still GameJournal.

`TabletopLaunchScreen.storyboard` supplies the static launch surface. `LaunchExperience` starts with the same 75%-visible brand as the static system screen, finishes the fade over 0.2 seconds, then translates a fixed-height composited landscape and content together over 0.85 seconds. The underlying header stays hidden until handoff. Reduce Motion uses a 0.47-second fade sequence without translation. No network request is required. Returning from background does not replay the animation. Assets are in `GameJournal/Assets.xcassets`.

### Simulator launch-screen signing
Build simulators with local ad-hoc signing enabled (no developer account needed):
```
xcodebuild -project GameJournal.xcodeproj -scheme GameJournal -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/GameJournalBuild CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- build
```
Do not use `CODE_SIGNING_ALLOWED=NO`: this iOS runtime rejects unsigned storyboard resources with error -67056 and displays a black system launch screen. Ad-hoc signing was verified to resolve it without resetting the simulator or journal data.

## Repository hygiene

The repository contains source, tests, and app artwork only. Local session data, feedback recordings, build products, provisioning profiles, and signing credentials are excluded.
