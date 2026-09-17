/// Maps SwiftDS's own catalog onto SwiftBoard. Import the **SwiftBoardKit** product
/// and call `SwiftBoardKit.registerAll()` — do not copy this file into the app.
@_exported import SwiftBoard
@_exported import SwiftBoardServer
import CoreFoundation
import CoreGraphics
import Foundation
import SwiftDS
import SwiftUI

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

        var coveredSlugs = registerFineGrainedComponents(into: board)
        coveredSlugs.formUnion(registerIsolatedComponents(into: board))
        registerShowroomMenu(into: board, skipping: coveredSlugs)
    }

    /// Components the SwiftDS catalog never enumerated per-state — the showroom instead dumps a
    /// giant shared page (e.g. all of `DataShowcase`) into every item, which snapshots as a blank
    /// strip. Register the real control instead.
    private static func registerIsolatedComponents(into board: SwiftBoard) -> Set<String> {
        board.addScenarios(
            category: "Data Display",
            component: "PromoLabel",
            summary: "Small tinted label for discounts and highlights (e.g. −20%, NEW). Not a status/pill with an icon — that is StatusLabel.",
            parameters: [
                ScenarioParameter(name: "text", type: "String", description: "Visible label."),
                ScenarioParameter(name: "color", type: "Color", defaultValue: "DSColor.error", description: "Fill + text tint."),
                ScenarioParameter(
                    name: "accessibilityLabel",
                    type: "String?",
                    defaultValue: "nil",
                    description: "VoiceOver label; falls back to text."
                )
            ]
        ) {
            Scenario(
                "Discount",
                docs: ScenarioDocs(snippet: "DSPromoLabel(\"−20%\")")
            ) { DSPromoLabel("−20%") }
            Scenario(
                "New",
                docs: ScenarioDocs(snippet: "DSPromoLabel(\"NEW\", color: DSColor.success)")
            ) { DSPromoLabel("NEW", color: DSColor.success) }
            Scenario(
                "Hot",
                docs: ScenarioDocs(snippet: "DSPromoLabel(\"HOT\", color: DSColor.warning)")
            ) { DSPromoLabel("HOT", color: DSColor.warning) }
            Scenario(
                "Sale",
                docs: ScenarioDocs(snippet: "DSPromoLabel(\"SALE\", color: DSColor.info)")
            ) { DSPromoLabel("SALE", color: DSColor.info) }
        }

        return ["data-display/promo-label"]
    }

    private static func registerFineGrainedComponents(into board: SwiftBoard) -> Set<String> {
        let grouped = Dictionary(grouping: DSComponentCatalog.all) {
            "\(Slug.make($0.category))/\(Slug.make($0.component))"
        }

        for key in grouped.keys.sorted() {
            guard let entries = grouped[key], let first = entries.first else { continue }

            let scenarios = entries.map { entry in
                Scenario(
                    displayName(for: entry.state),
                    layout: scenarioLayout(from: entry.layout),
                    docs: ScenarioDocs(snippet: catalogSnippet(entry)),
                    view: entry.view
                )
            }

            let guide = componentGuide(for: key)
            let states = entries.map { displayName(for: $0.state) }.joined(separator: ", ")
            board.addScenarios(
                category: displayName(for: first.category),
                component: displayName(for: first.component),
                summary: guide.summary ?? "SwiftDS catalog states: \(states).",
                parameters: guide.parameters,
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
                ? .fixed(width: CGFloat(390), height: CGFloat(700))
                : .fixed(width: CGFloat(390), height: CGFloat(640))

            for template in visibleTemplates {
                let key = "\(Slug.make(category.name))/\(Slug.make(template.name))"
                guard !coveredSlugs.contains(key) else { continue }

                board.addScenarios(
                    category: category.name,
                    component: template.name,
                    summary: "SwiftDS showroom screen for this item (the same page the showroom app opens). Isolated states + init parameters are only listed when the catalog registered them separately.",
                    scenarios: [
                        Scenario(
                            "Preview",
                            layout: layout,
                            docs: ScenarioDocs(
                                summary: "Top of the showroom page. ScrollViews often need a fixed viewport to snapshot."
                            ),
                            view: template.view
                        )
                    ]
                )
            }
        }
    }

    private static func catalogSnippet(_ entry: DSComponentCatalogEntry) -> String? {
        switch (entry.category, entry.component, entry.state) {
        case ("data-display", "badge", "filled"):
            return "DSBadge(\"New\", variant: .filled, color: DSColor.info)"
        case ("data-display", "badge", "soft"):
            return "DSBadge(\"Active\", variant: .soft, color: DSColor.success)"
        case ("data-display", "badge", "outline"):
            return "DSBadge(\"Pending\", variant: .outline, color: DSColor.warning)"
        case ("data-display", "status-label", "success"):
            return "DSStatusLabel(\"Delivered\", style: .success)"
        case ("data-display", "status-label", "warning"):
            return "DSStatusLabel(\"Pending\", style: .warning)"
        case ("data-display", "status-label", "error"):
            return "DSStatusLabel(\"Failed\", style: .error)"
        case ("data-display", "status-label", "info"):
            return "DSStatusLabel(\"In Review\", style: .info)"
        case ("data-display", "status-label", "neutral"):
            return "DSStatusLabel(\"Draft\", style: .neutral)"
        case ("actions", "button", "primary"):
            return "DSButton(\"Primary\", variant: .primary)"
        case ("actions", "button", "secondary"):
            return "DSButton(\"Secondary\", variant: .secondary)"
        case ("actions", "button", "ghost"):
            return "DSButton(\"Ghost\", variant: .ghost)"
        case ("actions", "button", "destructive"):
            return "DSButton(\"Delete\", variant: .destructive)"
        case ("actions", "button", "success"):
            return "DSButton(\"Success\", variant: .success, icon: \"checkmark\")"
        default:
            return nil
        }
    }

    private static func componentGuide(for key: String) -> (summary: String?, parameters: [ScenarioParameter]) {
        switch key {
        case "data-display/badge":
            return (
                "Count or short status chip. Variants change fill vs outline; color tints it.",
                [
                    ScenarioParameter(name: "text", type: "String", description: "Badge copy."),
                    ScenarioParameter(name: "variant", type: "DSBadgeVariant", description: ".filled, .soft, or .outline."),
                    ScenarioParameter(name: "color", type: "Color", description: "Tint (e.g. DSColor.info).")
                ]
            )
        case "data-display/status-label":
            return (
                "Inline status with optional leading icon. Use PromoLabel for sale/new tags without icons.",
                [
                    ScenarioParameter(name: "text", type: "String", description: "Status copy."),
                    ScenarioParameter(name: "style", type: "DSStatusLabelStyle", defaultValue: ".neutral", description: ".success, .warning, .error, .info, .neutral."),
                    ScenarioParameter(name: "showIcon", type: "Bool", defaultValue: "true", description: "Hides the SF Symbol when false."),
                    ScenarioParameter(name: "accessibilityLabel", type: "String?", defaultValue: "nil", description: "VoiceOver override.")
                ]
            )
        case "actions/button":
            return (
                "Primary action control. variant picks the visual style; optional icon sits beside the title.",
                [
                    ScenarioParameter(name: "title", type: "String", description: "Button label."),
                    ScenarioParameter(name: "variant", type: "DSButtonVariant", description: ".primary, .secondary, .ghost, .destructive, .success."),
                    ScenarioParameter(name: "icon", type: "String?", defaultValue: "nil", description: "Optional SF Symbol name.")
                ]
            )
        default:
            return (nil, [])
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
        kebab.split(separator: "-").map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined(separator: " ")
    }
}
