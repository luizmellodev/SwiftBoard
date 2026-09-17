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
        board.addScenarios(
            category: "Data Display",
            component: "Badge",
            summary: "Short status chip.",
            parameters: [
                ScenarioParameter(name: "title", type: "String"),
                ScenarioParameter(name: "color", type: "Color", defaultValue: ".green")
            ]
        ) {
            Scenario("Active", docs: ScenarioDocs(snippet: "DemoBadge(title: \"Active\", color: .green)")) {
                DemoBadge(title: "Active", color: .green)
            }
            Scenario("Pending", docs: ScenarioDocs(snippet: "DemoBadge(title: \"Pending\", color: .orange)")) {
                DemoBadge(title: "Pending", color: .orange)
            }
            Scenario("Failed", docs: ScenarioDocs(snippet: "DemoBadge(title: \"Failed\", color: .red)")) {
                DemoBadge(title: "Failed", color: .red)
            }
        }
    }
}
