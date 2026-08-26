@_exported import SwiftBoard
import Foundation
import SwiftUI

public enum StaticExporterError: Error {
    case missingResource(String)
}

/// Freezes every registered scenario into a self-contained static site folder
/// (index.html + app.css + app.js + manifest.json + snapshots/**/*.png), reusing the exact
/// same rendering path and relative-URL scheme as the live server.
public struct StaticExporter {
    public static func export(
        board: SwiftBoard? = nil,
        to directory: URL,
        scales: [Int] = [1, 2, 3],
        boardName: String = "SwiftBoard"
    ) async throws {
        let resolvedBoard: SwiftBoard
        if let board {
            resolvedBoard = board
        } else {
            resolvedBoard = await MainActor.run { SwiftBoard.shared }
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for name in ["index.html", "app.css", "app.js", "docs.html"] {
            guard let source = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Resources") else {
                throw StaticExporterError.missingResource(name)
            }
            let destination = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
        }

        let manifest = await MainActor.run { ManifestBuilder.build(from: resolvedBoard, boardName: boardName) }

        for category in manifest.categories {
            for component in category.components {
                for scenario in component.scenarios {
                    for isDark in [false, true] {
                        for scale in scales {
                            let data = await MainActor.run { () -> Data? in
                                guard
                                    let liveComponent = resolvedBoard.component(categorySlug: category.slug, componentSlug: component.slug),
                                    let liveScenario = liveComponent.scenarios.first(where: { $0.id == scenario.slug })
                                else {
                                    return nil
                                }
                                return ScenarioRenderer.renderPNG(
                                    scenario: liveScenario,
                                    scale: CGFloat(scale),
                                    colorScheme: isDark ? .dark : .light
                                )
                            }
                            guard let data else { continue }

                            let relativePath = SnapshotPath.relative(
                                categorySlug: category.slug,
                                componentSlug: component.slug,
                                scenarioSlug: scenario.slug,
                                scale: scale,
                                dark: isDark
                            )
                            let outputURL = directory.appendingPathComponent(relativePath)
                            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                            try data.write(to: outputURL)
                        }
                    }
                }
            }
        }

        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: directory.appendingPathComponent("manifest.json"))
    }
}
