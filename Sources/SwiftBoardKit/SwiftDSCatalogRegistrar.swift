@_exported import SwiftBoard
@_exported import SwiftBoardServer
import SwiftDS

/// Registers SwiftDS's existing component catalog (`DSComponentCatalog`) as SwiftBoard
/// scenarios, so running `SwiftBoardKitDemo` gives you the whole design system navigable
/// with no hand-written registration.
@MainActor
public enum SwiftDSCatalogRegistrar {
    public static func registerAll(into board: SwiftBoard? = nil) {
        let board = board ?? SwiftBoard.shared
        let grouped = Dictionary(grouping: DSComponentCatalog.all) { "\($0.category)/\($0.component)" }

        for key in grouped.keys.sorted() {
            guard let entries = grouped[key], let first = entries.first else { continue }

            let scenarios = entries.map { entry in
                Scenario(displayName(for: entry.state), layout: scenarioLayout(from: entry.layout), view: entry.view)
            }

            board.addScenarios(
                category: displayName(for: first.category),
                component: displayName(for: first.component),
                scenarios: scenarios
            )
        }
    }

    private static func scenarioLayout(from layout: DSCatalogLayout) -> ScenarioLayout {
        switch layout {
        case .fitContent(let maxWidth):
            return .fitContent(maxWidth: maxWidth)
        case .fixed(let width, let height):
            return .fixed(width: width, height: height)
        }
    }

    private static func displayName(for kebab: String) -> String {
        kebab.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}
