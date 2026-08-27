import AppKit
import SwiftUI
import SwiftBoardKit

@main
struct SwiftBoardKitDemoApp: App {
    @State private var server = BoardServer()
    @State private var statusText = "Starting…"
    @State private var iosDemoStatus = ""

    private let url = URL(string: "http://127.0.0.1:8080")!

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("SwiftBoard × SwiftDS").font(.title2).bold()
                Text(statusText).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("Open in Browser") {
                        NSWorkspace.shared.open(url)
                    }
                    Button("Run iOS Demo (Simulator)") {
                        iosDemoStatus = "Starting…"
                        do {
                            try Self.runIOSDemoScript()
                            iosDemoStatus = "Started"
                        } catch {
                            iosDemoStatus = "Failed: \(error)"
                        }
                    }
                }
                if !iosDemoStatus.isEmpty {
                    Text(iosDemoStatus).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(40)
            .frame(minWidth: 420, minHeight: 200)
            .task {
                SwiftDSCatalogRegistrar.registerAll()
                await server.addAction(title: "Run iOS Demo (Simulator)") {
                    try Self.runIOSDemoScript()
                }
                do {
                    try await server.start()
                    statusText = "Running at \(url.absoluteString)"
                } catch {
                    statusText = "Failed to start: \(error)"
                }
            }
        }
    }

    /// Launches Scripts/run-ios-demo.sh, resolved relative to this source file so it works
    /// regardless of the working directory `swift run` was invoked from.
    private nonisolated static func runIOSDemoScript() throws {
        let scriptURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Scripts/run-ios-demo.sh")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        try process.run()
    }
}
