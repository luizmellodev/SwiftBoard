import SwiftUI
import SwiftBoardServer

struct DemoBadge: View {
    let title: String
    var color: Color = .green

    var body: some View {
        Text(title)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

extension DemoBadge: BoardScenarioProvider {
    static func provideScenarios(into board: SwiftBoard) {
        board.addScenarios(category: "Data Display", component: "Badge") {
            Scenario("Active") { DemoBadge(title: "Active", color: .green) }
            Scenario("Pending") { DemoBadge(title: "Pending", color: .orange) }
            Scenario("Failed") { DemoBadge(title: "Failed", color: .red) }
        }
    }
}
