import SwiftUI
import SwiftBoardKit

/// Hosts `BoardGallery` inside an actual iOS app, so components render with real iOS chrome
/// (fonts, control styles, etc.) instead of macOS's — which is what `SwiftBoardDemo` /
/// `SwiftBoardKitDemo` would show if run as a plain macOS process. Also starts the website
/// server, so its snapshots are genuinely iOS-rendered too when opened from this device.
@main
struct SwiftBoardiOSDemoApp: App {
    @State private var server = BoardServer()

    var body: some Scene {
        WindowGroup {
            BoardGallery()
                .task {
                    SwiftDSCatalogRegistrar.registerAll()
                    try? await server.start()
                }
        }
    }
}
