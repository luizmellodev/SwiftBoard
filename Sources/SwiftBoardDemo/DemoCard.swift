import SwiftUI
import SwiftBoardServer

struct DemoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weekly report").font(.headline)
            Text("Everything looks good this week.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

extension DemoCard: BoardScenarioProvider {
    static func provideScenarios(into board: SwiftBoard) {
        board.addScenarios(category: "Data Display", component: "Card") {
            Scenario("Elevated", layout: .fitContent(maxWidth: 280)) { DemoCard() }
        }
    }
}
