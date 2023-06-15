import XCTest
@testable import NSViewProxy

final class NSViewProxyTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NSViewProxy().text, "Hello, World!")
    }
}
