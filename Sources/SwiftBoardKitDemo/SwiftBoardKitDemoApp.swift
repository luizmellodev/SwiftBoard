import AppKit
import SwiftUI
import SwiftBoardKit

@main
struct SwiftBoardKitDemoApp: App {
    @State private var server = BoardServer()
    @State private var statusText = "Starting…"
    @State private var showGallery = false

    private let url = URL(string: "http://127.0.0.1:8080")!

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("SwiftBoard × SwiftDS").font(.title2).bold()
                Text(statusText).foregroundStyle(.secondary)
                Button("Open in Browser") {
                    NSWorkspace.shared.open(url)
                }
                Button("Show Native Gallery") {
                    showGallery = true
                }
            }
            .padding(40)
            .frame(minWidth: 360, minHeight: 200)
            .sheet(isPresented: $showGallery) {
                BoardGallery()
                    .frame(minWidth: 700, minHeight: 480)
            }
            .task {
                SwiftDSCatalogRegistrar.registerAll()
                do {
                    try await server.start()
                    statusText = "Running at \(url.absoluteString)"
                } catch {
                    statusText = "Failed to start: \(error)"
                }
            }
        }
    }
}
