/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
@testable import ShellOut

#if os(Linux)
extension ShellOutTests {
    static var allTests = [
        ("testWithoutArguments", testWithoutArguments),
        ("testWithArguments", testWithArguments),
        ("testWithInlineArguments", testWithInlineArguments),
        ("testThrowingError", testThrowingError),
        ("testRedirection", testRedirection)
    ]
}
#endif
