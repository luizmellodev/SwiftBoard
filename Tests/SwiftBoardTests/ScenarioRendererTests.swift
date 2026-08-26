import XCTest
import SwiftUI
import Foundation
@testable import SwiftBoard

@MainActor
final class ScenarioRendererTests: XCTestCase {
    func testRendersNonEmptyPNGData() {
        let scenario = Scenario("Test") { Text("Hello") }
        let data = ScenarioRenderer.renderPNG(scenario: scenario, scale: 2, colorScheme: .light)

        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 0)
        XCTAssertEqual(data?.prefix(8), Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    }
}
