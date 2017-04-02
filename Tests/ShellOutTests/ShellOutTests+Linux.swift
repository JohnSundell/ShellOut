import XCTest
@testable import ShellOut

#if os(Linux)
extension ShellOutTests {
    static var allTests = [
        ("testWithoutArguments", testWithoutArguments),
        ("testWithArguments", testWithArguments),
        ("testWithInlineArguments", testWithInlineArguments),
        ("testThrowingError", testThrowingError)
    ]
}
#endif
