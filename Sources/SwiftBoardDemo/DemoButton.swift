import SwiftUI
import SwiftBoardServer

struct DemoButton: View {
    enum Style {
        case primary, secondary, disabled, loading
    }

    let title: String
    var style: Style = .primary

    var body: some View {
        switch style {
        case .primary:
            Button(title) {}.buttonStyle(.borderedProminent)
        case .secondary:
            Button(title) {}.buttonStyle(.bordered)
        case .disabled:
            Button(title) {}.buttonStyle(.borderedProminent).disabled(true)
        case .loading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(title)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.6), in: Capsule())
            .foregroundStyle(.white)
        }
    }
}

/// Registration lives right next to the component it describes — no separate giant file to
/// maintain as more components/states are added.
extension DemoButton: BoardScenarioProvider {
    static func provideScenarios(into board: SwiftBoard) {
        board.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") { DemoButton(title: "Continue", style: .primary) }
            Scenario("Secondary") { DemoButton(title: "Continue", style: .secondary) }
            Scenario("Disabled") { DemoButton(title: "Continue", style: .disabled) }
            Scenario("Loading", layout: .fitContent(maxWidth: 180)) { DemoButton(title: "Continue", style: .loading) }
        }
    }
}
