@_exported import SwiftBoard
@_exported import SwiftBoardServer
import SwiftDS

/// Registers SwiftDS's components as SwiftBoard scenarios, from two sources:
///
/// 1. `DSComponentCatalog` — hand-picked per-state entries (one small card per real variant:
///    Button/Primary, Button/Disabled, ...). Nicer, but only exists for the components someone
///    took the time to enumerate this way.
/// 2. SwiftDS's own showroom menu (`DSShowcaseMenu.categories`) — the exact same public data
///    that drives the `showroom` app's navigation, covering everything else (Navigation,
///    Layout, Marketing, Messaging, Foundations, the example apps under "Screens", etc.) as one
///    preview per entry, since that's the granularity `showroom` itself has for them.
///
/// (2) skips any category/component already covered by (1), so components with real variant
/// data don't also show a redundant "everything at once" screenshot.
@MainActor
public enum SwiftDSCatalogRegistrar {
    /// Exists for documentation/screenshot tooling (one giant concatenation of every screen),
    /// not for interactive browsing — not worth surfacing as its own category here.
    private static let excludedCategories: Set<String> = ["Documentation Screenshots"]

    /// Categories whose entries are full example screens/apps rather than a single small
    /// component — sized like a phone viewport instead of shrink-to-fit.
    private static let fullScreenCategories: Set<String> = ["Screens", "Showcases"]

    public static func registerAll(into board: SwiftBoard? = nil) {
        let board = board ?? SwiftBoard.shared

        let coveredSlugs = registerFineGrainedComponents(into: board)
        registerShowroomMenu(into: board, skipping: coveredSlugs)
    }

    private static func registerFineGrainedComponents(into board: SwiftBoard) -> Set<String> {
        let grouped = Dictionary(grouping: DSComponentCatalog.all) {
            "\(Slug.make($0.category))/\(Slug.make($0.component))"
        }

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

        return Set(grouped.keys)
    }

    private static func registerShowroomMenu(into board: SwiftBoard, skipping coveredSlugs: Set<String>) {
        for category in DSShowcaseMenu.categories {
            guard !excludedCategories.contains(category.name) else { continue }

            let visibleTemplates = category.templates.filter(\.showsInShowroom)
            guard !visibleTemplates.isEmpty else { continue }

            let layout: ScenarioLayout = fullScreenCategories.contains(category.name)
                ? .fixed(width: 390, height: 700)
                : .fitContent(maxWidth: 420)

            for template in visibleTemplates {
                let key = "\(Slug.make(category.name))/\(Slug.make(template.name))"
                guard !coveredSlugs.contains(key) else { continue }

                board.addScenarios(
                    category: category.name,
                    component: template.name,
                    scenarios: [Scenario("Preview", layout: layout, view: template.view)]
                )
            }
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
