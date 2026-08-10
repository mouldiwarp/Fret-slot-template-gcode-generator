#!/usr/bin/env swift

import Foundation
import AppKit

func generateIcon() {
    let size: CGFloat = 1024

    let image = NSImage(size: NSSize(width: size, height: size), flipped: false, drawingHandler: { rect in
        // Background: dark neck color
        NSColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 60, yRadius: 60).fill()

        // Border: lighter wood accent
        NSColor(red: 0.35, green: 0.30, blue: 0.25, alpha: 1.0).setStroke()
        let border = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 52, yRadius: 52)
        border.lineWidth = 4
        border.stroke()

        // Fret lines (vertical) - at equal-temperament positions
        let fretYPositions = [0.0, 0.05946, 0.11697, 0.17189, 0.22449, 0.27520, 0.32428, 0.37195, 0.41840, 0.46384, 0.50846, 0.55241, 0.59580]
        NSColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 0.8).setStroke()

        let startX = 60.0
        let endX = size - 60
        let fretStart = 80.0
        let fretEnd = size - 80

        for position in fretYPositions {
            let y = fretStart + CGFloat(position) * (fretEnd - fretStart)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: startX, y: y))
            path.line(to: NSPoint(x: endX, y: y))
            path.lineWidth = 2.5
            path.stroke()
        }

        // String lines (horizontal) - 4 strings for a bass/guitar feel
        NSColor(red: 0.70, green: 0.68, blue: 0.65, alpha: 0.9).setStroke()
        let stringStart = 120.0
        let stringEnd = size - 120
        let stringSpacing = (size - 240) / 5

        for i in 1...4 {
            let y = 120 + CGFloat(i) * CGFloat(stringSpacing)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: stringStart, y: y))
            path.line(to: NSPoint(x: stringEnd, y: y))
            path.lineWidth = 1.5
            path.stroke()
        }

        // Inlay dot (position marker) - at the 12th fret equivalent
        NSColor(red: 0.95, green: 0.85, blue: 0.40, alpha: 0.95).setFill()
        let dotX = (size / 2) - 15
        let dotY = fretStart + CGFloat(0.5) * (fretEnd - fretStart) - 15
        let dotRect = NSRect(x: dotX, y: dotY, width: 30, height: 30)
        NSBezierPath(ovalIn: dotRect).fill()

        // Highlight dot
        NSColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 0.6).setFill()
        let highlightRect = NSRect(x: dotX + 6, y: dotY + 6, width: 12, height: 12)
        NSBezierPath(ovalIn: highlightRect).fill()

        return true
    })

    // Create iconset directory
    let iconsetPath = "AppIcon.iconset"
    try? FileManager.default.removeItem(atPath: iconsetPath)
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    // Define icon sizes (standard macOS app icon)
    let sizes: [(size: Int, scale: String)] = [
        (16, "1x"), (16, "2x"),
        (32, "1x"), (32, "2x"),
        (64, "1x"), (64, "2x"),
        (128, "1x"), (128, "2x"),
        (256, "1x"), (256, "2x"),
        (512, "1x"), (512, "2x"),
        (1024, "1x")
    ]

    // Render each size via image resizing
    for (size, scale) in sizes {
        let sizePoints = CGFloat(size)
        let scaleNum = scale == "2x" ? 2.0 : 1.0
        let pixelSize = sizePoints * scaleNum

        let resizedImage = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        resizedImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
                   from: NSRect.zero,
                   operation: .copy,
                   fraction: 1.0)
        resizedImage.unlockFocus()

        guard let tiffData = resizedImage.tiffRepresentation,
              let resizedBitmap = NSBitmapImageRep(data: tiffData),
              let png = resizedBitmap.representation(using: .png, properties: [:]) else {
            print("✗ Failed to convert to PNG for size \(size)@\(scale)")
            continue
        }

        // Determine filename using macOS iconset naming convention
        let filename: String
        if scale == "2x" {
            filename = "icon_\(size)x\(size)@2x.png"
        } else {
            filename = "icon_\(size)x\(size).png"
        }

        let fileURL = URL(fileURLWithPath: "\(iconsetPath)/\(filename)")
        do {
            try png.write(to: fileURL)
            print("✓ Generated \(filename)")
        } catch {
            print("✗ Failed to write \(filename): \(error)")
        }
    }

    print("\nIcon set created at \(iconsetPath)/")
}

generateIcon()
