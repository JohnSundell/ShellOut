/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
@testable import ShellOut

class ShellOutTests: XCTestCase {
    func test_appendArguments() throws {
        var cmd = try ShellOutCommand(command: "foo")
        XCTAssertEqual(cmd.string, "foo")
        cmd.append(arguments: [";", "bar"].quoted)
        XCTAssertEqual(cmd.string, "foo ';' bar" )
        cmd.append(arguments: ["> baz".verbatim])
        XCTAssertEqual(cmd.string, "foo ';' bar > baz" )
    }

    func test_appendingArguments() throws {
        let cmd = try ShellOutCommand(command: "foo")
        XCTAssertEqual(
            cmd.appending(arguments: [";", "bar"].quoted).string,
            "foo ';' bar"
        )
        XCTAssertEqual(
            cmd.appending(arguments: [";", "bar"].quoted)
                .appending(arguments: ["> baz".verbatim])
                .string,
            "foo ';' bar > baz"
        )
    }

    func testWithoutArguments() throws {
        let uptime = try shellOut(to: "uptime".safe)
        XCTAssertTrue(uptime.contains("load average"))
    }

    func testWithArguments() throws {
        let echo = try shellOut(to: "echo".safe, arguments: ["Hello world".quoted])
        XCTAssertEqual(echo, "Hello world")
    }

    func testSingleCommandAtPath() throws {
        try shellOut(
            to: "echo".safe,
            arguments: [#"Hello" > \#(NSTemporaryDirectory())ShellOutTests-SingleCommand.txt"#.quoted]
        )

        let textFileContent = try shellOut(
            to: "cat".safe,
            arguments:  ["ShellOutTests-SingleCommand.txt".quoted],
            at: NSTemporaryDirectory()
        )

        XCTAssertEqual(textFileContent, "Hello")
    }

    func testSingleCommandAtPathContainingSpace() throws {
        try shellOut(to: "mkdir".safe,
                     arguments: ["-p".verbatim, "ShellOut Test Folder".quoted],
                     at: NSTemporaryDirectory())
        try shellOut(to: "echo".safe, arguments: ["Hello",  ">",  "File"].verbatim,
                     at: NSTemporaryDirectory() + "ShellOut Test Folder")

        let output = try shellOut(
            to: "cat".safe,
            arguments: ["\(NSTemporaryDirectory())ShellOut Test Folder/File".quoted])
        XCTAssertEqual(output, "Hello")
    }

    func testSingleCommandAtPathContainingTilde() throws {
        let homeContents = try shellOut(to: "ls".safe, at: "~")
        XCTAssertFalse(homeContents.isEmpty)
    }

    func testThrowingError() {
        do {
            try shellOut(to: "cd".safe, arguments: ["notADirectory".verbatim])
            XCTFail("Expected expression to throw")
        } catch let error as ShellOutError {
            XCTAssertTrue(error.message.contains("notADirectory"))
            XCTAssertTrue(error.output.isEmpty)
            XCTAssertTrue(error.terminationStatus != 0)
        } catch {
            XCTFail("Invalid error type: \(error)")
        }
    }

    func testErrorDescription() {
        let errorMessage = "Hey, I'm an error!"
        let output = "Some output"

        let error = ShellOutError(
            terminationStatus: 7,
            errorData: errorMessage.data(using: .utf8)!,
            outputData: output.data(using: .utf8)!
        )

        let expectedErrorDescription = """
                                       ShellOut encountered an error
                                       Status code: 7
                                       Message: "Hey, I'm an error!"
                                       Output: "Some output"
                                       """

        XCTAssertEqual("\(error)", expectedErrorDescription)
        XCTAssertEqual(error.localizedDescription, expectedErrorDescription)
    }

    func testCapturingOutputWithHandle() throws {
        let pipe = Pipe()
        let output = try shellOut(to: "echo".safe,
                                  arguments: ["Hello".verbatim],
                                  outputHandle: pipe.fileHandleForWriting)
        let capturedData = pipe.fileHandleForReading.readDataToEndOfFile()
        XCTAssertEqual(output, "Hello")
        XCTAssertEqual(output + "\n", String(data: capturedData, encoding: .utf8))
    }

    func testCapturingErrorWithHandle() throws {
        let pipe = Pipe()

        do {
            try shellOut(to: "cd".safe,
                         arguments: ["notADirectory".verbatim],
                         errorHandle: pipe.fileHandleForWriting)
            XCTFail("Expected expression to throw")
        } catch let error as ShellOutError {
            XCTAssertTrue(error.message.contains("notADirectory"))
            XCTAssertTrue(error.output.isEmpty)
            XCTAssertTrue(error.terminationStatus != 0)

            let capturedData = pipe.fileHandleForReading.readDataToEndOfFile()
            XCTAssertEqual(error.message + "\n", String(data: capturedData, encoding: .utf8))
        } catch {
            XCTFail("Invalid error type: \(error)")
        }
    }

    func test_createFile() throws {
        let tempFolderPath = NSTemporaryDirectory()
        try shellOut(to: .createFile(named: "Test", contents: "Hello world"),
                     at: tempFolderPath)
        XCTAssertEqual(try shellOut(to: .readFile(at: tempFolderPath + "Test")),
                       "Hello world")
    }

    func testGitCommands() throws {
        // Setup & clear state
        let tempFolderPath = NSTemporaryDirectory()
        try shellOut(to: "rm".safe,
                     arguments: ["-rf", "GitTestOrigin"].verbatim,
                     at: tempFolderPath)
        try shellOut(to: "rm".safe,
                     arguments: ["-rf", "GitTestClone"].verbatim,
                     at: tempFolderPath)

        // Create a origin repository and make a commit with a file
        let originPath = tempFolderPath + "/GitTestOrigin"
        try shellOut(to: .createFolder(named: "GitTestOrigin"), at: tempFolderPath)
        try shellOut(to: .gitInit(), at: originPath)
        try shellOut(to: .createFile(named: "Test", contents: "Hello world"), at: originPath)
        try shellOut(to: .gitCommit(message: "Commit"), at: originPath)

        // Clone to a new repository and read the file
        let clonePath = tempFolderPath + "/GitTestClone"
        let cloneURL = URL(fileURLWithPath: originPath)
        try shellOut(to: .gitClone(url: cloneURL, to: "GitTestClone"), at: tempFolderPath)

        let filePath = clonePath + "/Test"
        XCTAssertEqual(try shellOut(to: .readFile(at: filePath)), "Hello world")

        // Make a new commit in the origin repository
        try shellOut(to: .createFile(named: "Test", contents: "Hello again"), at: originPath)
        try shellOut(to: .gitCommit(message: "Commit"), at: originPath)

        // Pull the commit in the clone repository and read the file again
        try shellOut(to: .gitPull(), at: clonePath)
        XCTAssertEqual(try shellOut(to: .readFile(at: filePath)), "Hello again")
    }

    func testSwiftPackageManagerCommands() throws {
        // Setup & clear state
        let tempFolderPath = NSTemporaryDirectory()
        try shellOut(to: "rm".safe,
                     arguments: ["-rf", "SwiftPackageManagerTest"].verbatim,
                     at: tempFolderPath)
        try shellOut(to: .createFolder(named: "SwiftPackageManagerTest"), at: tempFolderPath)

        // Create a Swift package and verify that it has a Package.swift file
        let packagePath = tempFolderPath + "/SwiftPackageManagerTest"
        try shellOut(to: .createSwiftPackage(), at: packagePath)
        XCTAssertFalse(try shellOut(to: .readFile(at: packagePath + "/Package.swift")).isEmpty)

        // Build the package and verify that there's a .build folder
        try shellOut(to: .buildSwiftPackage(), at: packagePath)
        XCTAssertTrue(
            try shellOut(to: "ls".safe, arguments: ["-a".verbatim], at: packagePath) .contains(".build")
        )

        // Generate an Xcode project
        try shellOut(to: .generateSwiftPackageXcodeProject(), at: packagePath)
        XCTAssertTrue(
            try shellOut(to: "ls".safe, arguments: ["-a".verbatim], at: packagePath)
                .contains("SwiftPackageManagerTest.xcodeproj")
        )
    }

    func testArgumentQuoting() throws {
        XCTAssertEqual(try shellOut(to: "echo".safe,
                                    arguments: ["foo ; echo bar".quoted]),
                       "foo ; echo bar")
        XCTAssertEqual(try shellOut(to: "echo".safe,
                                    arguments: ["foo ; echo bar".verbatim]),
                       "foo\nbar")
    }
}
