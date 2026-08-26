@_exported import SwiftBoard
import FlyingFox
import Foundation
import SwiftUI

/// Embedded HTTP server that serves a live, browsable website of every registered scenario.
public actor BoardServer {
    public struct Configuration: Sendable {
        public var port: UInt16

        public init(port: UInt16 = 8080) {
            self.port = port
        }
    }

    private let configuration: Configuration
    private let httpServer: HTTPServer
    private let cache = SnapshotCache()
    private var runTask: Task<Void, Error>?

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
        self.httpServer = HTTPServer(port: configuration.port)
    }

    /// Starts the server. No-ops in Release builds unless `SWIFTBOARD_ENABLE=1` is set.
    public func start() async throws {
        #if !DEBUG
        guard ProcessInfo.processInfo.environment["SWIFTBOARD_ENABLE"] == "1" else {
            print("SwiftBoard: disabled in Release builds. Set SWIFTBOARD_ENABLE=1 to opt in.")
            return
        }
        #endif

        await registerRoutes()

        let server = httpServer
        runTask = Task { try await server.run() }
        try await server.waitUntilListening()
        print("SwiftBoard running at http://127.0.0.1:\(configuration.port)")
    }

    public func stop() async {
        await httpServer.stop(timeout: 3)
        runTask?.cancel()
        runTask = nil
    }

    private func registerRoutes() async {
        await httpServer.appendRoute("GET /") { _ in
            StaticAssets.response(for: "index.html")
        }
        await httpServer.appendRoute("GET /app.css") { _ in
            StaticAssets.response(for: "app.css")
        }
        await httpServer.appendRoute("GET /app.js") { _ in
            StaticAssets.response(for: "app.js")
        }
        await httpServer.appendRoute("GET /docs") { _ in
            StaticAssets.response(for: "docs.html")
        }

        await httpServer.appendRoute("GET /manifest.json") { _ in
            let manifest = await MainActor.run { ManifestBuilder.build(from: SwiftBoard.shared) }
            guard let data = try? JSONEncoder().encode(manifest) else {
                return HTTPResponse(statusCode: .internalServerError)
            }
            return HTTPResponse(statusCode: .ok, headers: [.contentType: "application/json; charset=utf-8"], body: data)
        }

        let cache = self.cache
        await httpServer.appendRoute("GET /snapshots/:category/:component/:file") { request in
            guard
                let categorySlug = request.routeParameters["category"],
                let componentSlug = request.routeParameters["component"],
                let file = request.routeParameters["file"],
                let key = SnapshotKey(categorySlug: categorySlug, componentSlug: componentSlug, file: file)
            else {
                return HTTPResponse(statusCode: .notFound)
            }

            let revision = await MainActor.run { SwiftBoard.shared.revision }
            let data = await cache.data(for: key.cacheKey, revision: revision) {
                await MainActor.run { () -> Data? in
                    guard
                        let component = SwiftBoard.shared.component(categorySlug: key.categorySlug, componentSlug: key.componentSlug),
                        let scenario = component.scenarios.first(where: { $0.id == key.scenarioSlug })
                    else {
                        return nil
                    }
                    return ScenarioRenderer.renderPNG(
                        scenario: scenario,
                        scale: CGFloat(key.scale),
                        colorScheme: key.isDark ? .dark : .light
                    )
                }
            }

            guard let data else { return HTTPResponse(statusCode: .notFound) }
            return HTTPResponse(statusCode: .ok, headers: [.contentType: "image/png", .cacheControl: "no-store"], body: data)
        }
    }
}
