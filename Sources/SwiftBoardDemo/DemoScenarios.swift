import SwiftBoardServer

/// The only place that needs to know about every component — everything about *how* each one
/// renders lives in that component's own file (see DemoButton.swift, DemoBadge.swift,
/// DemoCard.swift). Adding a component means adding one line here, not growing this file's body.
enum DemoScenarios {
    @MainActor
    static func registerAll() {
        SwiftBoard.shared.addScenarios(from: [
            DemoButton.self,
            DemoBadge.self,
            DemoCard.self
        ])
    }
}
