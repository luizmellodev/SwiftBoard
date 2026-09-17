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
    private var actions: [BoardAction] = []

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
        self.httpServer = HTTPServer(port: configuration.port)
    }

    /// Registers a custom action, shown as a button on the site. Runs only for requests from
    /// the local machine (127.0.0.1), never from another device on the network, even though the
    /// server itself listens on all interfaces. Call before `start()`.
    public func addAction(title: String, id: String? = nil, run: @escaping @Sendable () async throws -> Void) {
        actions.append(BoardAction(title: title, id: id, run: run))
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
        let task = Task.detached { try await server.run() }
        runTask = task

        do {
            try await server.waitUntilListening()
        } catch {
            task.cancel()
            throw BoardServerError.failedToStart(port: configuration.port, underlying: error)
        }

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

        let actionSummaries = actions.map { ActionSummary(id: $0.id, title: $0.title) }
        await httpServer.appendRoute("GET /manifest.json") { _ in
            let manifest = await MainActor.run { ManifestBuilder.build(from: SwiftBoard.shared) }
            let response = ManifestResponse(boardName: manifest.boardName, categories: manifest.categories, actions: actionSummaries)
            guard let data = try? JSONEncoder().encode(response) else {
                return HTTPResponse(statusCode: .internalServerError)
            }
            return HTTPResponse(statusCode: .ok, headers: [.contentType: "application/json; charset=utf-8"], body: data)
        }

        await httpServer.appendRoute("POST /actions/:id") { request in
            guard Self.isLocalRequest(request) else {
                return HTTPResponse(statusCode: .forbidden)
            }
            guard
                let id = request.routeParameters["id"],
                let action = await self.action(withID: id)
            else {
                return HTTPResponse(statusCode: .notFound)
            }
            do {
                try await action.run()
                return HTTPResponse(statusCode: .ok)
            } catch {
                return HTTPResponse(statusCode: .internalServerError)
            }
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

    private func action(withID id: String) -> BoardAction? {
        actions.first { $0.id == id }
    }

    /// Trusts only the actual socket peer address — deliberately ignores `X-Forwarded-For`
    /// (client-controlled, spoofable), since this gates code execution, not just a redirect.
    private static func isLocalRequest(_ request: HTTPRequest) -> Bool {
        switch request.remoteAddress {
        case .ip4(let ip, port: _):
            return ip == "127.0.0.1"
        case .ip6(let ip, port: _):
            // IPv4-mapped IPv6 (e.g. "::ffff:127.0.0.1") is what a dual-stack listener
            // typically reports for a plain IPv4 loopback connection, not just "::1".
            return ip == "::1" || ip == "::ffff:127.0.0.1"
        case .unix:
            return true
        case .none:
            return false
        }
    }
}

public enum BoardServerError: Error, CustomStringConvertible {
    case failedToStart(port: UInt16, underlying: Error)

    public var description: String {
        switch self {
        case .failedToStart(let port, let underlying):
            return "SwiftBoard couldn't start on port \(port). If another instance is already " +
                "running (another SwiftBoard-based app, or a previous run you forgot to stop), " +
                "stop it and try again. Underlying error: \(underlying)"
        }
    }
}

private struct ManifestResponse: Encodable {
    let boardName: String
    let categories: [ManifestCategory]
    let actions: [ActionSummary]
}

private struct ActionSummary: Encodable {
    let id: String
    let title: String
}
