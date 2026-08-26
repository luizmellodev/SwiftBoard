/// A named component within a category, holding every state (`Scenario`) registered for it.
@MainActor
public struct Component: Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public internal(set) var scenarios: [Scenario]
}
