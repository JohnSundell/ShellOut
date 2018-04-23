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
        ("testSingleCommandAtPath", testSingleCommandAtPath),
        ("testSeriesOfCommands", testSeriesOfCommands),
        ("testSeriesOfCommandsAtPath", testSeriesOfCommandsAtPath),
        ("testThrowingError", testThrowingError),
        ("testGitCommands", testGitCommands),
        ("testSwiftPackageManagerCommands", testSwiftPackageManagerCommands),
        ("testWithoutArgumentsAsynchronously", testWithoutArguments),
        ("testWithArgumentsAsynchronously", testWithArguments),
        ("testWithInlineArgumentsAsynchronously", testWithInlineArguments),
        ("testSingleCommandAtPathAsynchronously", testSingleCommandAtPath),
        ("testSeriesOfCommandsAsynchronously", testSeriesOfCommands),
        ("testSeriesOfCommandsAtPathAsynchronously", testSeriesOfCommandsAtPath),
        ("testThrowingErrorAsynchronously", testThrowingError),
        ("testGitCommandsAsynchronously", testGitCommands),
        ("testSwiftPackageManagerCommandsAsynchronously", testSwiftPackageManagerCommands)
    ]
}
#endif
