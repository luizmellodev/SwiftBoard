/// Lets a component register its own scenarios right next to its definition, instead of in one
/// giant registration file. Conform your component's own type to this (in the same file as the
/// component, the same way you'd add a `#Preview` block) and list the conforming types once,
/// wherever you call `addScenarios(from:)`.
@MainActor
public protocol BoardScenarioProvider {
    static func provideScenarios(into board: SwiftBoard)
}

extension SwiftBoard {
    /// Registers every provider's scenarios, in the order given.
    public func addScenarios(from providers: [any BoardScenarioProvider.Type]) {
        for provider in providers {
            provider.provideScenarios(into: self)
        }
    }
}
