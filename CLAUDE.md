# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

### Build and Install
```bash
./build.sh
```

This is the single command that does everything: compiles the Swift binary, generates the app icon, assembles the `.app` bundle, signs it, installs to `~/Applications`, and registers with Spotlight.

### Rebuild Without Installing
```bash
swift build -c release
```

Binary output: `.build/arm64-apple-macosx/release/fret-template-builder`

### Launch the App
```bash
open ~/Applications/"Fret Template Builder.app"
```

Or via Spotlight: Cmd+Space → "Fret Template Builder"

### Verify Core Logic
```bash
swift verify.swift
```

Tests fret calculation formula (fret 0 = 0, fret 12 = scale/2, fret 24 = scale*0.75) and G-code structure (G21, G90, no M3/M5, M30 at end).

---

## Architecture

**Model Layer** (pure logic, no UI dependencies):
- `Models/FretCalculator.swift` — Equal-temperament fret position calculator using the formula: `distance(n) = scaleLength * (1 - 1 / 2^(n/12))`
- `Models/GCodeGenerator.swift` — Converts fret positions + parameters into GRBL G-code text. Handles comment style toggle (parentheses vs. semicolons).

**View Layer** (SwiftUI):
- `Views/ContentView.swift` — Main UI: form for inputs (scale, frets, parameters), split-pane table + G-code preview, Generate and Export buttons.
- `FretTemplateBuilderApp.swift` — `@main` entry point using SwiftUI's `App` protocol.

**Key Design**:
- Auto-generation on parameter change (`.onChange` handlers on all inputs)
- "Regenerate" button for manual refresh (available even if unchanged from defaults)
- Export filename dynamic: `fret-slot-template-{scale}-{frets}.nc`
- No dependencies; all logic is pure Swift using only stdlib + SwiftUI/AppKit

---

## Important Implementation Details

### Build System (No Xcode Required)

The app is built with **Swift Package Manager only**. No `.xcodeproj`, no full Xcode needed — only Command Line Tools.

- **Binary creation**: `swift build -c release` produces an executable at `.build/arm64-apple-macosx/release/fret-template-builder`
- **Bundle assembly**: `build.sh` manually assembles the `.app` directory structure:
  ```
  Fret Template Builder.app/
  ├── Contents/
  │   ├── Info.plist
  │   ├── PkgInfo (literal "APPL????")
  │   ├── MacOS/fret-template-builder (copied binary)
  │   └── Resources/AppIcon.icns
  ```
- **Ad-hoc signing**: `codesign -s -` to prevent stale-signature errors across rebuilds
- **Spotlight registration**: `mdimport ~/Applications/"Fret Template Builder.app"` to force indexing

### G-Code Generation

Always starts from **fret 0 at CNC X=0** (the nut is the reference point). All fret positions are absolute distances in mm from the nut.

**Default parameters** (user-editable):
- Plunge Depth: 6.0 mm
- Safe Z: 5.0 mm
- Feed Rate: 200.0 mm/min
- Comment Style: Parentheses (toggle to semicolons if needed)

Export saves as `.nc` file (pure G-code, no `.txt` extension appended).

### UI Behavior

- **Input fields**: Empty placeholders, no default text shown (cleaner interface)
- **Fret table**: Auto-updates as you type scale length or fret count
- **G-code preview**: Auto-generates whenever any parameter changes (scale, frets, depths, feed rate, comment style)
- **Export button**: Only enabled after G-code is generated; saves with dynamic filename based on current inputs

---

## File Organization

```
Sources/FretTemplateBuilder/
├── FretTemplateBuilderApp.swift
├── Models/
│   ├── FretCalculator.swift        (pure formula: distance(n) = length * (1 - 1/2^(n/12)))
│   └── GCodeGenerator.swift        (pure text generation; handles CommentStyle enum)
└── Views/
    └── ContentView.swift           (SwiftUI form + Table + TextEditor)

Resources/
├── Info.plist                      (app metadata: bundle ID, name, icon file, version)
└── AppIcon.icns                    (icon file, generated from PNG via iconutil)

build.sh                            (orchestration: compile → icon → bundle → sign → install)
Package.swift                       (SwiftPM configuration)
verify.swift                        (standalone verification of core logic)
```

---

## Common Tasks

### Add a New Parameter to G-Code

1. Add field to `GCodeParameters` struct in `GCodeGenerator.swift`
2. Add `@State` variable and TextField in `ContentView.swift`
3. Add `.onChange` handler to the TextField
4. Update `GCodeGenerator.generate()` to use the new parameter

### Change Default Values

Edit the `@State` initial values in `ContentView.swift` (e.g., `@State private var feedRateMMPerMin: Double = 200.0`)

### Modify the Fret Calculation Formula

Edit `FretCalculator.compute()` in `Models/FretCalculator.swift`. Test with `swift verify.swift` to confirm.

### Update the App Icon

1. Prepare a PNG image (ideally 1024×1024 or larger)
2. Replace `/path/to/home/Downloads/` image source
3. Run `./build.sh` — it will regenerate the icon and rebuild the app

---

## Testing & Verification

**Unit testing**: Not available in this SwiftPM setup (no XCTest integration via CLT). Instead:
- Use `verify.swift` for formula and G-code structure validation
- Run the app manually to test UI behavior

**Before committing changes**:
1. `swift build -c release` — ensure it compiles
2. `swift verify.swift` — confirm fret calculations and G-code format
3. `./build.sh` — full rebuild and install
4. Launch the app and test manually (change scale length, check auto-generation, export a file)

---

## Swift Version & Dependencies

- **Swift**: 6.0+ (uses strict concurrency, Swift 6 language mode)
- **Platforms**: macOS 14.0+ (Sonoma)
- **Dependencies**: None — uses only stdlib, SwiftUI, and AppKit
- **Warnings to expect**: Deprecation warnings on `onChange(of:perform:)` (use new `onChange` signatures in future updates)

---

## Notes for Future Work

- **Sandbox**: App is unsandboxed; no entitlements file needed. `NSSavePanel` works without special configuration.
- **Ad-hoc signing**: Rebuilt binaries need re-signing to avoid LaunchServices cache issues; `build.sh` handles this.
- **Spotlight indexing**: May take a moment after install; `mdimport` forces immediate indexing.
- **Window size**: Hardcoded to 1000×600 to accommodate the split-pane table + preview layout.
- **String formatting**: All numeric outputs use specific precision (%.2f for mm, %.4f for inches in calculations).

