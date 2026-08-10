import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var scaleLengthText: String = "25.5"
    @State private var fretCountText: String = "24"
    @State private var holeDiameterMM: Double = 4.0
    @State private var plungeDepthMM: Double = 6.0
    @State private var safeZMM: Double = 5.0
    @State private var feedRateMMPerMin: Double = 200.0
    @State private var useSemicolonComments: Bool = false
    @State private var generatedGCode: String?

    private var scaleLengthIn: Double? {
        Double(scaleLengthText)
    }

    private var fretCount: Int? {
        Int(fretCountText)
    }

    private var frets: [FretPosition] {
        guard let scaleLength = scaleLengthIn, scaleLength > 0,
              let count = fretCount, count > 0 else {
            return []
        }
        return FretCalculator.compute(scaleLengthIn: scaleLength, fretCount: count)
    }

    var body: some View {
        VStack(spacing: 16) {
            Form {
                Section("Scale Settings") {
                    LabeledContent("Scale Length (in):") {
                        TextField("", text: $scaleLengthText)
                            .frame(width: 100)
                            .onChange(of: scaleLengthText) { _ in autoGenerateGCode() }
                    }
                    LabeledContent("Fret Count:") {
                        TextField("", text: $fretCountText)
                            .frame(width: 100)
                            .onChange(of: fretCountText) { _ in autoGenerateGCode() }
                    }
                }

                Section("G-Code Parameters") {
                    LabeledContent("Hole Diameter (mm):") {
                        TextField("", value: $holeDiameterMM, format: .number)
                            .frame(width: 100)
                            .onChange(of: holeDiameterMM) { _ in autoGenerateGCode() }
                    }
                    LabeledContent("Plunge Depth (mm):") {
                        TextField("", value: $plungeDepthMM, format: .number)
                            .frame(width: 100)
                            .onChange(of: plungeDepthMM) { _ in autoGenerateGCode() }
                    }
                    LabeledContent("Safe Z (mm):") {
                        TextField("", value: $safeZMM, format: .number)
                            .frame(width: 100)
                            .onChange(of: safeZMM) { _ in autoGenerateGCode() }
                    }
                    LabeledContent("Feed Rate (mm/min):") {
                        TextField("", value: $feedRateMMPerMin, format: .number)
                            .frame(width: 100)
                            .onChange(of: feedRateMMPerMin) { _ in autoGenerateGCode() }
                    }
                    Toggle("Use Semicolon Comments (;)", isOn: $useSemicolonComments)
                        .onChange(of: useSemicolonComments) { _ in autoGenerateGCode() }
                }
            }

            HStack(spacing: 16) {
                // Left: Fret Positions Table
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fret Positions")
                        .font(.headline)

                    if !frets.isEmpty {
                        Table(frets) {
                            TableColumn("Fret") { fret in
                                Text("\(fret.id)")
                            }
                            TableColumn("From Nut (mm)") { fret in
                                Text(String(format: "%.2f", fret.distanceFromNutIn * 25.4))
                            }
                            TableColumn("Spacing (mm)") { fret in
                                Text(String(format: "%.2f", fret.spacingFromPrevIn * 25.4))
                            }
                        }
                        .frame(maxHeight: 400)
                    } else {
                        VStack {
                            Spacer()
                            Text("Enter scale length and fret count")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(Color.gray, width: 1)
                    }
                }
                .frame(maxWidth: .infinity)

                // Right: G-Code Preview Pane
                VStack(alignment: .leading, spacing: 8) {
                    Text("G-Code Preview")
                        .font(.headline)

                    if let gcode = generatedGCode {
                        TextEditor(text: .constant(gcode))
                            .font(.system(.body, design: .monospaced))
                            .border(Color.gray, width: 1)
                    } else {
                        VStack {
                            Spacer()
                            Text("Click 'Generate' to create G-code")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(Color.gray, width: 1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            // Buttons
            HStack(spacing: 12) {
                Button("Regenerate") {
                    generateGCode()
                }
                .disabled(frets.isEmpty)

                Spacer()

                Button("Export G-Code") {
                    exportGCode()
                }
                .disabled(generatedGCode == nil || frets.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 1000, minHeight: 600)
    }

    private func generateGCode() {
        guard let scaleLength = scaleLengthIn else { return }

        let commentStyle: CommentStyle = useSemicolonComments ? .semicolon : .parentheses

        let params = GCodeParameters(
            holeDiameterMM: holeDiameterMM,
            plungeDepthMM: plungeDepthMM,
            safeZMM: safeZMM,
            feedRateMMPerMin: feedRateMMPerMin,
            commentStyle: commentStyle
        )

        generatedGCode = GCodeGenerator.generate(scaleLengthIn: scaleLength, frets: frets, params: params)
    }

    private func autoGenerateGCode() {
        guard !frets.isEmpty else { return }
        generateGCode()
    }

    private func exportGCode() {
        guard let gcodeString = generatedGCode else { return }

        let filename = "fret-slot-template-\(scaleLengthText)-\(fretCountText).nc"

        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop")
        panel.nameFieldStringValue = filename
        panel.allowedContentTypes = []

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try gcodeString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
        }
    }
}
