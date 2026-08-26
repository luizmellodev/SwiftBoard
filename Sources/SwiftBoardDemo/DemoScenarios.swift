import SwiftUI
import SwiftBoardServer

/// A handful of plain-SwiftUI scenarios, registered with no dependency on any specific design
/// system — proves the "light" path end-to-end.
enum DemoScenarios {
    @MainActor
    static func registerAll() {
        registerButtons()
        registerBadges()
        registerCards()
    }

    @MainActor
    private static func registerButtons() {
        SwiftBoard.shared.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") {
                Button("Continue") {}.buttonStyle(.borderedProminent)
            }
            Scenario("Secondary") {
                Button("Continue") {}.buttonStyle(.bordered)
            }
            Scenario("Disabled") {
                Button("Continue") {}.buttonStyle(.borderedProminent).disabled(true)
            }
            Scenario("Loading", layout: .fitContent(maxWidth: 180)) {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Continue")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.6), in: Capsule())
                .foregroundStyle(.white)
            }
        }
    }

    @MainActor
    private static func registerBadges() {
        SwiftBoard.shared.addScenarios(category: "Data Display", component: "Badge") {
            badge("Active", color: .green)
            badge("Pending", color: .orange)
            badge("Failed", color: .red)
        }
    }

    @MainActor
    private static func badge(_ title: String, color: Color) -> Scenario {
        Scenario(title) {
            Text(title)
                .font(.caption).bold()
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(color.opacity(0.15), in: Capsule())
                .foregroundStyle(color)
        }
    }

    @MainActor
    private static func registerCards() {
        SwiftBoard.shared.addScenarios(category: "Data Display", component: "Card") {
            Scenario("Elevated", layout: .fitContent(maxWidth: 280)) {
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
    }
}
