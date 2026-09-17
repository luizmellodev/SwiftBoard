/// A named component within a category, holding every state (`Scenario`) registered for it.
@MainActor
public struct Component: Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public var summary: String?
    public var parameters: [ScenarioParameter]
    public internal(set) var scenarios: [Scenario]

    /// Registered copy, or a fallback listing every named state so the site is never silent.
    public var resolvedSummary: String {
        if let summary, !summary.isEmpty { return summary }
        let names = scenarios.map(\.name)
        if names.isEmpty { return "No states registered yet." }
        return "States: " + names.joined(separator: ", ") + "."
    }
}
