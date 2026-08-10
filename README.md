# Fret Template Builder

A native macOS app that calculates fret positions for instrument necks and generates CNC G-code drilling templates for a WorkBee Z1+ CNC.

## Features

- **Fret Position Calculator**: Computes equal-temperament fret positions from a scale length
- **Live Table Display**: Shows fret number, distance from nut, and spacing between frets in inches
- **G-Code Generator**: Exports GRBL-format G-code for drilling 4mm marker holes on a CNC
- **Configurable Parameters**: Adjustable plunge depth, safe Z height, and feed rates
- **Native App**: Installed to `~/Applications`, discoverable via Spotlight (Cmd+Space)
- **Custom Icon**: Stylized fretboard icon

## Installation

The app is already installed at `/path/to/home/Applications/Fret Template Builder.app`.

To use it:
1. Press **Cmd+Space** to open Spotlight
2. Type "Fret Template Builder"
3. Press Enter to launch

Or launch directly:
```bash
open ~/Applications/"Fret Template Builder.app"
```

## Building from Source

### Prerequisites
- Swift 6.0+ (included with macOS 14+)
- Xcode Command Line Tools (no full Xcode required)
- `iconutil` and `sips` (standard macOS utilities)

### Build & Install

```bash
cd /path/to/scale-template
./build.sh
```

This will:
1. Compile the Swift package in release mode
2. Generate the app icon from Core Graphics drawing
3. Assemble the `.app` bundle with proper structure
4. Ad-hoc codesign the bundle
5. Install to `~/Applications`
6. Register with Spotlight

### Manual Rebuild Without Install

To rebuild without reinstalling:
```bash
swift build -c release
```

The binary will be at `.build/arm64-apple-macosx/release/fret-template-builder`.

## Usage

### Input Parameters

1. **Scale Length (in)**: Guitar scale length in inches (e.g., 25.5 for Fender)
2. **Fret Count**: Number of frets to include (e.g., 24)
3. **Hole Diameter (mm)**: Documentation comment for the G-code (default: 4.0)
4. **Plunge Depth (mm)**: Z-axis plunge distance (default: 8.0)
5. **Safe Z (mm)**: Retract/rapid height above workpiece (default: 5.0)
6. **Feed Rate (mm/min)**: XY rapid and Z plunge speed (default: 150.0)

### Fret Calculation

Fret positions are calculated using the equal-temperament formula:
```
distance(n) = scaleLengthIn * (1 - 1 / 2^(n/12))
spacing(n) = distance(n) - distance(n-1)
```

For a 25.5" scale:
- Fret 0 (nut) = 0.0"
- Fret 12 (octave) = 12.75"
- Fret 24 = 19.125"

### G-Code Export

Click **Export G-code...** to save a `.gcode` file suitable for the WorkBee Z1+ Duo controller.

The G-code:
- Uses **G21** (millimeters) with inch-to-mm conversion (×25.4)
- Uses **G90** (absolute positioning)
- Drills holes along **Y=0** (center line), X axis positions
- Contains **no spindle commands** (M3/M5) — drill manually
- Ranges from **Fret 0** to the **fret count** you entered
- Ends with **M30** (program end)

### Example G-Code Structure

```gcode
(Fret Template Builder - GRBL G-code)
(Scale Length: 25.500 in / 647.700 mm)
(Fret Count: 24)
(Hole Diameter: 4.000 mm - documentation only)

G21
G90
(Fret 0)
G0 Z5.000
G0 X0.000 Y0.000
G1 Z-8.000 F150.000
G0 Z5.000
(Fret 1)
G0 Z5.000
G0 X36.353 Y0.000
G1 Z-8.000 F150.000
G0 Z5.000
...
G0 Z5.000
M30
```

## Project Structure

```
/path/to/scale-template/
├── Package.swift                         # Swift Package configuration
├── build.sh                              # Build & install script
├── verify.swift                          # Manual verification script
├── Resources/
│   ├── Info.plist                        # macOS app metadata
│   └── AppIcon.icns                      # App icon (1024×1024 @2x)
├── Scripts/
│   └── generate_icon.swift               # Icon generation from Core Graphics
├── Sources/FretTemplateBuilder/
│   ├── FretTemplateBuilderApp.swift      # @main app entry point
│   ├── Views/
│   │   └── ContentView.swift             # SwiftUI form + table + export UI
│   └── Models/
│       ├── FretCalculator.swift          # Fret position calculation logic
│       └── GCodeGenerator.swift          # G-code text generation
└── dist/
    └── Fret Template Builder.app/        # Built app bundle (temporary)
```

## Code Files

### `FretCalculator.swift`
Pure calculation logic (no UI dependencies).

**Key type**: `FretPosition` — stores fret ID, distance from nut, and spacing.

**Main function**: `FretCalculator.compute(scaleLengthIn:fretCount:) -> [FretPosition]`

### `GCodeGenerator.swift`
Pure G-code text generation (no UI dependencies).

**Key type**: `GCodeParameters` — holds plunge depth, safe Z, feed rate, hole diameter.

**Main function**: `GCodeGenerator.generate(scaleLengthIn:frets:params:) -> String`

### `ContentView.swift`
SwiftUI form and table UI.

- Text fields for scale length and fret count
- Editable G-code parameters
- SwiftUI `Table` displaying fret positions (macOS 12+)
- "Export G-code..." button with `NSSavePanel` (defaults to Desktop)

### `FretTemplateBuilderApp.swift`
SwiftUI `@main` entry point using the `App` protocol.

## Verification

Run the verification script to test the core logic:

```bash
swift verify.swift
```

Output:
- Fret distance calculations (exact values at frets 0, 12, 24)
- Spacing decrease check (earlier frets have larger spacing)
- G-code structure validation (G21, G90, no M3/M5, M30 at end)
- Sample G-code excerpt
- Test file export to `/tmp/fret-template-sample.gcode`

## Known Limitations

- **No spindle control**: You must manually control the drill motor (as requested)
- **Simple drilling**: Point-drilling only, no pocket operations
- **Fixed centerline**: Always drills at Y=0 (center line on X axis)
- **Desktop save default**: Can be changed via the save dialog
- **No entitlements**: App is unsandboxed, has full filesystem access

## Customization

### Change the App Icon

Edit `Scripts/generate_icon.swift` to modify the fretboard drawing (colors, lines, inlay position), then run:

```bash
swift Scripts/generate_icon.swift
rm Resources/AppIcon.icns
iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns
./build.sh
```

### Change Default G-Code Parameters

Edit the `GCodeParameters()` struct initialization in `Sources/FretTemplateBuilder/Views/ContentView.swift`:

```swift
let params = GCodeParameters(
    holeDiameterMM: 4.0,      // Change here
    plungeDepthMM: 8.0,       // Change here
    safeZMM: 5.0,             // Change here
    feedRateMMPerMin: 150.0   // Change here
)
```

### Change App Name or Bundle ID

Edit `Resources/Info.plist` and update:
- `CFBundleIdentifier`: change `com.gary.fret-template-builder` to your own
- `CFBundleName`: change `Fret Template Builder` to your app name

Then rebuild: `./build.sh`

## Troubleshooting

### App doesn't appear in Spotlight

Re-register:
```bash
mdimport ~/Applications/"Fret Template Builder.app"
```

### App won't launch

Check for codesigning issues:
```bash
codesign --verify -v ~/Applications/"Fret Template Builder.app"
```

Re-sign if needed:
```bash
codesign --force --deep --sign - ~/Applications/"Fret Template Builder.app"
```

### Build fails

Clean and rebuild:
```bash
rm -rf .build AppIcon.iconset
swift build -c release
./build.sh
```

## Technical Details

### SwiftUI on macOS without Xcode

The app is built entirely with Swift Package Manager (`swift build -c release`), not Xcode's `xcodebuild`. The resulting executable is hand-wrapped into a `.app` bundle by copying:

1. Binary to `Contents/MacOS/<executable>`
2. Icon to `Contents/Resources/AppIcon.icns`
3. `Info.plist` to `Contents/`
4. `PkgInfo` (8 bytes: `APPL????`) to `Contents/`

SwiftUI's `@main App` protocol works seamlessly in this setup — no special configuration needed.

### Ad-hoc Codesigning

Apps built locally are signed with `codesign -s -` (ad-hoc), which:
- Prevents "app is damaged" errors on rebuild
- Allows LaunchServices (Spotlight) reliable registration
- Is necessary because unsigned bundles can have inconsistent behavior across runs

### Deployment Target

The app targets macOS 14.0 (Sonoma). It requires:
- SwiftUI (available since macOS 10.15)
- `Table` view (macOS 12+)
- `NSSavePanel` with AppKit interop (all macOS versions)

## License

Built for personal CNC tooling. Feel free to modify and redistribute.
