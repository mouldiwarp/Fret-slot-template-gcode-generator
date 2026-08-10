#!/usr/bin/env swift

import Foundation

// Reproduce the core logic for manual verification

struct FretPosition: Identifiable {
    let id: Int
    let distanceFromNutIn: Double
    let spacingFromPrevIn: Double
}

enum FretCalculator {
    static func compute(scaleLengthIn: Double, fretCount: Int) -> [FretPosition] {
        var frets: [FretPosition] = []
        var previousDistance: Double = 0

        for n in 0...fretCount {
            let distance = scaleLengthIn * (1 - 1 / pow(2, Double(n) / 12))
            let spacing = n == 0 ? 0 : distance - previousDistance
            frets.append(FretPosition(id: n, distanceFromNutIn: distance, spacingFromPrevIn: spacing))
            previousDistance = distance
        }

        return frets
    }
}

struct GCodeParameters {
    var holeDiameterMM: Double = 4.0
    var plungeDepthMM: Double = 8.0
    var safeZMM: Double = 5.0
    var feedRateMMPerMin: Double = 150.0
}

enum GCodeGenerator {
    static func generate(scaleLengthIn: Double, frets: [FretPosition], params: GCodeParameters) -> String {
        var gcode = ""

        let scaleLengthMM = scaleLengthIn * 25.4
        gcode += "(Fret Template Builder - GRBL G-code)\n"
        gcode += "(Scale Length: \(String(format: "%.3f", scaleLengthIn)) in / \(String(format: "%.3f", scaleLengthMM)) mm)\n"
        gcode += "(Fret Count: \(frets.count - 1))\n"
        gcode += "(Hole Diameter: \(String(format: "%.3f", params.holeDiameterMM)) mm - documentation only)\n"
        gcode += "\n"

        gcode += "G21\n"
        gcode += "G90\n"

        for fret in frets {
            gcode += "(Fret \(fret.id))\n"
            gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"

            let xMM = fret.distanceFromNutIn * 25.4
            gcode += "G0 X\(String(format: "%.3f", xMM)) Y0.000\n"
            gcode += "G1 Z-\(String(format: "%.3f", params.plungeDepthMM)) F\(String(format: "%.3f", params.feedRateMMPerMin))\n"
            gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"
        }

        gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"
        gcode += "M30\n"

        return gcode
    }
}

// Test suite
print("=== Fret Template Builder Verification ===\n")

// Test 1: Formula correctness
print("Test 1: Fret distance calculations (25.5\" scale)")
let scaleLengthIn = 25.5
let frets = FretCalculator.compute(scaleLengthIn: scaleLengthIn, fretCount: 24)

print("Fret 0 (nut): \(String(format: "%.4f", frets[0].distanceFromNutIn))\" (expected 0.0000\")")
print("Fret 12 (octave): \(String(format: "%.4f", frets[12].distanceFromNutIn))\" (expected \(String(format: "%.4f", scaleLengthIn / 2))\")")
print("Fret 24: \(String(format: "%.4f", frets[24].distanceFromNutIn))\" (expected \(String(format: "%.4f", scaleLengthIn * 0.75))\")")

let epsilon = 0.0001
let fret12 = frets[12].distanceFromNutIn
let fret24 = frets[24].distanceFromNutIn
let checkFret12 = abs(fret12 - (scaleLengthIn / 2)) < epsilon
let checkFret24 = abs(fret24 - (scaleLengthIn * 0.75)) < epsilon

print("Fret 12 check: \(checkFret12 ? "✓ PASS" : "✗ FAIL")")
print("Fret 24 check: \(checkFret24 ? "✓ PASS" : "✗ FAIL")\n")

// Test 2: Spacing decreases
print("Test 2: Spacing decreases with fret number")
let spacingCheck = (1..<10).allSatisfy { i in
    frets[i].spacingFromPrevIn > frets[i + 1].spacingFromPrevIn
}
print("Spacing decreases: \(spacingCheck ? "✓ PASS" : "✗ FAIL")\n")

// Test 3: G-code generation
print("Test 3: G-code generation for 5 frets")
let params = GCodeParameters()
let gcode = GCodeGenerator.generate(scaleLengthIn: scaleLengthIn, frets: Array(frets.prefix(6)), params: params)

let hasG21 = gcode.contains("G21")
let hasG90 = gcode.contains("G90")
let hasNoM3 = !gcode.contains("M3")
let hasNoM5 = !gcode.contains("M5")
let endsWithM30 = gcode.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("M30")
let hasAllFrets = (0...5).allSatisfy { gcode.contains("(Fret \($0))") }
let allYZero = gcode.split(separator: "\n").filter { $0.contains("G0 X") && $0.contains("Y") }.allSatisfy { $0.contains("Y0.000") }

print("Has G21: \(hasG21 ? "✓" : "✗")")
print("Has G90: \(hasG90 ? "✓" : "✗")")
print("No M3: \(hasNoM3 ? "✓" : "✗")")
print("No M5: \(hasNoM5 ? "✓" : "✗")")
print("Ends with M30: \(endsWithM30 ? "✓" : "✗")")
print("All fret comments: \(hasAllFrets ? "✓" : "✗")")
print("All Y = 0: \(allYZero ? "✓" : "✗")\n")

// Test 4: Sample G-code excerpt
print("Test 4: Sample G-code excerpt (first 3 frets)")
print(String(repeating: "-", count: 50))
let shortFrets = Array(frets.prefix(4))
let sampleGcode = GCodeGenerator.generate(scaleLengthIn: scaleLengthIn, frets: shortFrets, params: params)
let sampleLines = sampleGcode.split(separator: "\n", omittingEmptySubsequences: false).map(String.init).prefix(30)
for line in sampleLines {
    print(line)
}
print(String(repeating: "-", count: 50))

// Test 5: Save to file
print("\nTest 5: Export sample G-code file")
let exportPath = "/tmp/fret-template-sample.gcode"
do {
    try sampleGcode.write(toFile: exportPath, atomically: true, encoding: .utf8)
    let size = try FileManager.default.attributesOfItem(atPath: exportPath)[.size] as? Int ?? 0
    print("✓ Exported to \(exportPath) (\(size) bytes)")
} catch {
    print("✗ Failed to write file: \(error)")
}

print("\n=== Verification Complete ===")
