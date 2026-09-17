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

    func testFitContentDoesNotStretchToMaxWidth() {
        let scenario = Scenario("Tiny", layout: .fitContent(maxWidth: 375)) {
            Text("Hi")
        }
        guard let data = ScenarioRenderer.renderPNG(scenario: scenario, scale: 2, colorScheme: .light),
              let size = pngPixelSize(data)
        else {
            return XCTFail("expected PNG")
        }

        // 375pt at 2x would be 750px; a two-letter label must be much narrower.
        XCTAssertLessThan(size.width, 400)
        XCTAssertGreaterThan(size.width, 8)
        XCTAssertGreaterThan(size.height, 8)
    }

    private func pngPixelSize(_ data: Data) -> (width: Int, height: Int)? {
        guard data.count >= 24 else { return nil }
        let width = data.subdata(in: 16..<20).withUnsafeBytes { Int($0.load(as: UInt32.self).bigEndian) }
        let height = data.subdata(in: 20..<24).withUnsafeBytes { Int($0.load(as: UInt32.self).bigEndian) }
        return (width, height)
    }
}
