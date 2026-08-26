import XCTest
import SwiftUI
@testable import SwiftBoard

@MainActor
final class ManifestBuilderTests: XCTestCase {
    func testBuildsExpectedTreeShape() {
        let board = SwiftBoard()
        board.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") { Text("Hi") }
            Scenario("Disabled") { Text("Hi") }
        }

        let manifest = ManifestBuilder.build(from: board, boardName: "Test")

        XCTAssertEqual(manifest.boardName, "Test")
        XCTAssertEqual(manifest.categories.count, 1)

        let category = manifest.categories[0]
        XCTAssertEqual(category.name, "Actions")
        XCTAssertEqual(category.slug, "actions")
        XCTAssertEqual(category.components.count, 1)

        let component = category.components[0]
        XCTAssertEqual(component.slug, "button")
        XCTAssertEqual(component.scenarios.map(\.slug), ["primary", "disabled"])
        XCTAssertEqual(component.scenarios[0].snapshots.light.scale2x, "snapshots/actions/button/primary@2x.png")
        XCTAssertEqual(component.scenarios[0].snapshots.dark.scale2x, "snapshots/actions/button/primary@2x-dark.png")
    }

    func testDedupesCollidingScenarioNames() {
        let board = SwiftBoard()
        board.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") { Text("Hi") }
            Scenario("Primary") { Text("Hi") }
        }

        let manifest = ManifestBuilder.build(from: board)
        let slugs = manifest.categories[0].components[0].scenarios.map(\.slug)
        XCTAssertEqual(slugs, ["primary", "primary-2"])
    }
}
