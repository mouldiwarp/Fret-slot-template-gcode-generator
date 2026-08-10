import Foundation

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
