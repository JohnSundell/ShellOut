/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
import ShellOut

class ShellOutTests: XCTestCase {
    func testWithoutArguments() throws {
        let uptime = try shellOut(to: "uptime")
        XCTAssertTrue(uptime.contains("load average"))
    }

    func testWithArguments() throws {
        let echo = try shellOut(to: "echo", arguments: ["Hello world"])
        XCTAssertEqual(echo, "Hello world")
    }

    func testWithInlineArguments() throws {
        let echo = try shellOut(to: "echo \"Hello world\"")
        XCTAssertEqual(echo, "Hello world")
    }

    func testSingleCommandAtPath() throws {
        try shellOut(to: "echo \"Hello\" > \(NSTemporaryDirectory())ShellOutTests-SingleCommand.txt")

        let textFileContent = try shellOut(to: "cat ShellOutTests-SingleCommand.txt",
                                           at: NSTemporaryDirectory())

        XCTAssertEqual(textFileContent, "Hello")
    }

    func testSeriesOfCommands() throws {
        let echo = try shellOut(to: ["echo \"Hello\"", "echo \"world\""])
        XCTAssertEqual(echo, "Hello\nworld")
    }

    func testSeriesOfCommandsAtPath() throws {
        try shellOut(to: [
            "cd \(NSTemporaryDirectory())",
            "mkdir -p ShellOutTests",
            "echo \"Hello again\" > ShellOutTests/MultipleCommands.txt"
        ])

        let textFileContent = try shellOut(to: [
            "cd ShellOutTests",
            "cat MultipleCommands.txt"
        ], at: NSTemporaryDirectory())

        XCTAssertEqual(textFileContent, "Hello again")
    }

    func testThrowingError() {
        do {
            try shellOut(to: "cd", arguments: ["notADirectory"])
            XCTFail("Expected expression to throw")
        } catch let error as ShellOutError {
            XCTAssertTrue(error.message.contains("notADirectory"))
            XCTAssertTrue(error.output.isEmpty)
            XCTAssertTrue(error.terminationStatus != 0)
        } catch {
            XCTFail("Invalid error type: \(error)")
        }
    }

    func testRedirection() {

        let stdout = Pipe()
        do {
            try shellOut(to: "echo", arguments: ["Hello"], outputHandle: stdout.fileHandleForWriting)
            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            XCTAssertTrue(data.count > 0)
        } catch {
             XCTFail("Invalid error type: \(error)")
        }

        let stderr = Pipe()
        do {
            try shellOut(to: "echo", arguments: ["Hello", ">>/dev/stderr"], errorHandle: stderr.fileHandleForWriting)
            let data = stderr.fileHandleForReading.readDataToEndOfFile()
            XCTAssertTrue(data.count > 0)
        } catch {
            XCTFail("Invalid error type: \(error)")
        }
    }

}
