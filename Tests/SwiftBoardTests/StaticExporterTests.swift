import XCTest
import SwiftUI
@testable import SwiftBoardServer

@MainActor
final class StaticExporterTests: XCTestCase {
    func testExportWritesShellManifestAndSnapshots() async throws {
        let board = SwiftBoard()
        board.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") { Text("Go") }
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftboard-export-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        try await StaticExporter.export(board: board, to: directory, scales: [1])

        for name in ["index.html", "app.css", "app.js", "docs.html", "manifest.json"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path), name)
        }
        let snapshot = SnapshotPath.relative(categorySlug: "actions", componentSlug: "button", scenarioSlug: "primary", scale: 1, dark: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent(snapshot).path))
    }
}
