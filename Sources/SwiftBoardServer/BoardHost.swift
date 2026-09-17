import SwiftUI

public extension View {
    /// Starts the board server after `register` runs, and shows a small live badge so a
    /// developer knows the site is up. Does not replace or wrap the app's own UI.
    ///
    /// Tap the badge to open the in-app gallery. Copy the URL from the top of that list
    /// and paste it in a Mac browser for the full website.
    func swiftBoard(
        port: UInt16 = 8080,
        register: @escaping @MainActor () -> Void
    ) -> some View {
        BoardHost(port: port, register: register, content: self)
    }
}

private struct BoardHost<Content: View>: View {
    let port: UInt16
    let register: @MainActor () -> Void
    let content: Content

    @State private var server: BoardServer
    @State private var status: Status = .starting
    @State private var showBoard = false

    private enum Status: Equatable {
        case starting
        case running
        case failed(String)
    }

    init(port: UInt16, register: @escaping @MainActor () -> Void, content: Content) {
        self.port = port
        self.register = register
        self.content = content
        _server = State(initialValue: BoardServer(configuration: .init(port: port)))
    }

    var body: some View {
        content
            .overlay(alignment: .bottomTrailing) {
                badge
                    .padding(.trailing, 16)
                    .padding(.bottom, 20)
                    .zIndex(999)
            }
            .sheet(isPresented: $showBoard) {
                BoardGallery(websiteURL: URL(string: "http://127.0.0.1:\(port)"))
            }
            .task(id: port) {
                register()
                do {
                    try await server.start()
                    status = .running
                } catch {
                    status = .failed(String(describing: error))
                }
            }
    }

    private var badge: some View {
        Button {
            showBoard = true
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SwiftBoard")
                        .font(.caption.weight(.semibold))
                    Text(subtitle)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open SwiftBoard")
    }

    private var subtitle: String {
        switch status {
        case .starting: return "starting…"
        case .running: return "127.0.0.1:\(port)"
        case .failed(let message): return message
        }
    }

    private var dotColor: Color {
        switch status {
        case .starting: return .yellow
        case .running: return .green
        case .failed: return .red
        }
    }
}
