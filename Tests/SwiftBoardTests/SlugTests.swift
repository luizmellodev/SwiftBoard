import XCTest
@testable import SwiftBoard

final class SlugTests: XCTestCase {
    func testLowercasesAndReplacesSeparators() {
        XCTAssertEqual(Slug.make("Primary Button"), "primary-button")
    }

    func testCollapsesConsecutiveSeparators() {
        XCTAssertEqual(Slug.make("Foo   Bar!!"), "foo-bar")
    }

    func testTrimsTrailingSeparators() {
        XCTAssertEqual(Slug.make("Trailing-"), "trailing")
    }

    func testEmptyInputFallsBackToItem() {
        XCTAssertEqual(Slug.make("!!!"), "item")
    }
}
