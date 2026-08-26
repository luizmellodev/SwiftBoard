@resultBuilder
public struct ScenarioBuilder {
    public static func buildBlock(_ scenarios: Scenario...) -> [Scenario] {
        scenarios
    }

    public static func buildOptional(_ scenarios: [Scenario]?) -> [Scenario] {
        scenarios ?? []
    }

    public static func buildEither(first scenarios: [Scenario]) -> [Scenario] {
        scenarios
    }

    public static func buildEither(second scenarios: [Scenario]) -> [Scenario] {
        scenarios
    }

    public static func buildArray(_ scenarios: [[Scenario]]) -> [Scenario] {
        scenarios.flatMap { $0 }
    }
}
