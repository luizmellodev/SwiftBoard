import Observation

/// The runtime registry of every category/component/scenario registered by the host app.
///
/// `@Observable` so `BoardGallery` refreshes automatically when scenarios are registered after
/// the view has already appeared (the common case: register, *then* start the server in the
/// same `.task`) — without it, SwiftUI has no signal that this reference type's contents changed
/// and the gallery would stay empty until something else happened to trigger a re-render.
@MainActor
@Observable
public final class SwiftBoard {
    public static let shared = SwiftBoard()

    /// Bumped on every registration; used to invalidate rendered-snapshot caches.
    public private(set) var revision: Int = 0

    private var components: [String: Component] = [:]
    private var order: [String] = []

    /// Most apps should use `.shared`; a fresh instance is occasionally useful for tests.
    public init() {}

    public func addScenarios(
        category: String,
        component: String,
        summary: String? = nil,
        parameters: [ScenarioParameter] = [],
        @ScenarioBuilder scenarios: () -> [Scenario]
    ) {
        addScenarios(
            category: category,
            component: component,
            summary: summary,
            parameters: parameters,
            scenarios: scenarios()
        )
    }

    /// Data-driven overload for bulk registration (e.g. from an existing design system's catalog).
    public func addScenarios(
        category: String,
        component: String,
        summary: String? = nil,
        parameters: [ScenarioParameter] = [],
        scenarios: [Scenario]
    ) {
        let categorySlug = Slug.make(category)
        let componentSlug = Slug.make(component)
        let key = "\(categorySlug)/\(componentSlug)"

        var entry = components[key] ?? Component(
            id: componentSlug,
            name: component,
            category: category,
            summary: summary,
            parameters: parameters,
            scenarios: []
        )
        if entry.summary == nil { entry.summary = summary }
        if entry.parameters.isEmpty { entry.parameters = parameters }
        entry.scenarios = Self.dedupe(entry.scenarios + scenarios)
        components[key] = entry

        if !order.contains(key) {
            order.append(key)
        }

        revision += 1
    }

    var allComponentsInOrder: [Component] {
        order.compactMap { components[$0] }
    }

    public func component(categorySlug: String, componentSlug: String) -> Component? {
        components["\(categorySlug)/\(componentSlug)"]
    }

    /// Every registered component, grouped by category and in first-registered order.
    /// Shared by `ManifestBuilder` (website) and `BoardGallery` (native view) so both
    /// present components in the same order.
    public var categorizedComponents: [CategoryGroup] {
        var categorySlugOrder: [String] = []
        var categoryNames: [String: String] = [:]
        var componentsByCategory: [String: [Component]] = [:]

        for component in allComponentsInOrder {
            let categorySlug = Slug.make(component.category)
            if categoryNames[categorySlug] == nil {
                categoryNames[categorySlug] = component.category
                categorySlugOrder.append(categorySlug)
                componentsByCategory[categorySlug] = []
            }
            componentsByCategory[categorySlug, default: []].append(component)
        }

        return categorySlugOrder.map { slug in
            CategoryGroup(id: slug, name: categoryNames[slug] ?? slug, components: componentsByCategory[slug] ?? [])
        }
    }

    private static func dedupe(_ scenarios: [Scenario]) -> [Scenario] {
        var seen: Set<String> = []
        return scenarios.map { scenario in
            guard !seen.contains(scenario.id) else {
                var suffix = 2
                var candidate = "\(scenario.id)-\(suffix)"
                while seen.contains(candidate) {
                    suffix += 1
                    candidate = "\(scenario.id)-\(suffix)"
                }
                seen.insert(candidate)
                return scenario.withID(candidate)
            }
            seen.insert(scenario.id)
            return scenario
        }
    }
}
