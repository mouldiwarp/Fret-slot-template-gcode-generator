import Foundation

enum CommentStyle {
    case parentheses  // (comment)
    case semicolon    // ; comment
}

struct GCodeParameters {
    var holeDiameterMM: Double = 4.0
    var plungeDepthMM: Double = 8.0
    var safeZMM: Double = 5.0
    var feedRateMMPerMin: Double = 150.0
    var commentStyle: CommentStyle = .parentheses
}

enum GCodeGenerator {
    private static func comment(_ text: String, style: CommentStyle) -> String {
        switch style {
        case .parentheses:
            return "(\(text))"
        case .semicolon:
            return "; \(text)"
        }
    }

    static func generate(scaleLengthIn: Double, frets: [FretPosition], params: GCodeParameters) -> String {
        var gcode = ""
        let style = params.commentStyle

        // Header comments
        let scaleLengthMM = scaleLengthIn * 25.4
        gcode += comment("Fret Template Builder - GRBL G-code", style: style) + "\n"
        gcode += comment("Scale Length: \(String(format: "%.3f", scaleLengthIn)) in / \(String(format: "%.3f", scaleLengthMM)) mm", style: style) + "\n"
        gcode += comment("Fret Count: \(frets.count - 1)", style: style) + "\n"
        gcode += comment("Hole Diameter: \(String(format: "%.3f", params.holeDiameterMM)) mm - documentation only", style: style) + "\n"
        gcode += "\n"

        // Program start
        gcode += "G21\n"
        gcode += "G90\n"

        // Drill each fret
        for fret in frets {
            gcode += comment("Fret \(fret.id)", style: style) + "\n"
            gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"

            let xMM = fret.distanceFromNutIn * 25.4
            gcode += "G0 X\(String(format: "%.3f", xMM)) Y0.000\n"
            gcode += "G1 Z-\(String(format: "%.3f", params.plungeDepthMM)) F\(String(format: "%.3f", params.feedRateMMPerMin))\n"
            gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"
        }

        // Program end
        gcode += "G0 Z\(String(format: "%.3f", params.safeZMM))\n"
        gcode += "M30\n"

        return gcode
    }
}
