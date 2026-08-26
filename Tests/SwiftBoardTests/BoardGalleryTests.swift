import XCTest
import SwiftUI
@testable import SwiftBoard

@MainActor
final class BoardGalleryTests: XCTestCase {
    func testRendersWithoutCrashingWhenEmpty() {
        let board = SwiftBoard()
        let renderer = ImageRenderer(content: BoardGallery(board: board).frame(width: 600, height: 400))
        XCTAssertNotNil(renderer.cgImage)
    }

    func testRendersWithoutCrashingWithRegisteredScenarios() {
        let board = SwiftBoard()
        board.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") { Text("Hi") }
            Scenario("Disabled") { Text("Hi") }
        }

        let renderer = ImageRenderer(content: BoardGallery(board: board).frame(width: 600, height: 400))
        XCTAssertNotNil(renderer.cgImage)
    }
}
