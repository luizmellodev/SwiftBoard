import Foundation

/// One initializer argument a host can document next to a scenario or component.
public struct ScenarioParameter: Codable, Equatable, Sendable {
    public var name: String
    public var type: String
    public var defaultValue: String?
    public var description: String?

    public init(
        name: String,
        type: String,
        defaultValue: String? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
    }
}

/// Optional copy shown on the website / gallery: what this state *is*, the code that built it,
/// and (usually at the component level) which parameters exist.
public struct ScenarioDocs: Codable, Equatable, Sendable {
    public var summary: String?
    public var snippet: String?
    public var parameters: [ScenarioParameter]

    public static let empty = ScenarioDocs()

    public init(
        summary: String? = nil,
        snippet: String? = nil,
        parameters: [ScenarioParameter] = []
    ) {
        self.summary = summary
        self.snippet = snippet
        self.parameters = parameters
    }

    public var isEmpty: Bool {
        let hasSummary = !(summary?.isEmpty ?? true)
        let hasSnippet = !(snippet?.isEmpty ?? true)
        return !hasSummary && !hasSnippet && parameters.isEmpty
    }
}
