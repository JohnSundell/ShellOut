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
        let uptime = try shellOut(to: "uptime".checked).stdout
        XCTAssertTrue(uptime.contains("load average"))
    }

    func testWithArguments() throws {
        let echo = try shellOut(to: "echo".checked, arguments: ["Hello world".quoted]).stdout
        XCTAssertEqual(echo, "Hello world")
    }

    func testSingleCommandAtPath() throws {
        let tempDir = NSTemporaryDirectory()
        try shellOut(
            to: "echo".checked,
            arguments: ["Hello", ">".verbatim, "\(tempDir)ShellOutTests-SingleCommand.txt".quoted]
        )

        let textFileContent = try shellOut(
            to: "cat".checked,
            arguments:  ["ShellOutTests-SingleCommand.txt".quoted],
            at: tempDir
        ).stdout

        XCTAssertEqual(textFileContent, "Hello")
    }

    func testSingleCommandAtPathContainingSpace() throws {
        try shellOut(to: "mkdir".checked,
                     arguments: ["-p".verbatim, "ShellOut Test Folder".quoted],
                     at: NSTemporaryDirectory())
        try shellOut(to: "echo".checked, arguments: ["Hello",  ">",  "File"].verbatim,
                     at: NSTemporaryDirectory() + "ShellOut Test Folder")

        let output = try shellOut(
            to: "cat".checked,
            arguments: ["\(NSTemporaryDirectory())ShellOut Test Folder/File".quoted]).stdout
        XCTAssertEqual(output, "Hello")
    }

    func testSingleCommandAtPathContainingTilde() throws {
        let homeContents = try shellOut(to: "ls".checked, arguments: ["-a"], at: "~").stdout
        XCTAssertFalse(homeContents.isEmpty)
    }

    func testThrowingError() {
        do {
            try shellOut(to: "cd".checked, arguments: ["notADirectory".verbatim])
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
        let output = try shellOut(to: "echo".checked,
                                  arguments: ["Hello".verbatim],
                                  outputHandle: pipe.fileHandleForWriting).stdout
        let capturedData = pipe.fileHandleForReading.readDataToEndOfFile()
        XCTAssertEqual(output, "Hello")
        XCTAssertEqual(output + "\n", String(data: capturedData, encoding: .utf8))
    }

    func testCapturingErrorWithHandle() throws {
        let pipe = Pipe()

        do {
            try shellOut(to: "cd".checked,
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
        XCTAssertEqual(try shellOut(to: .readFile(at: tempFolderPath + "Test")).stdout,
                       "Hello world")
    }

    func testGitCommands() throws {
        // Setup & clear state
        let tempFolderPath = NSTemporaryDirectory()
        try shellOut(to: "rm".checked,
                     arguments: ["-rf", "GitTestOrigin"].verbatim,
                     at: tempFolderPath)
        try shellOut(to: "rm".checked,
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
        XCTAssertEqual(try shellOut(to: .readFile(at: filePath)).stdout, "Hello world")

        // Make a new commit in the origin repository
        try shellOut(to: .createFile(named: "Test", contents: "Hello again"), at: originPath)
        try shellOut(to: .gitCommit(message: "Commit"), at: originPath)

        // Pull the commit in the clone repository and read the file again
        try shellOut(to: .gitPull(), at: clonePath)
        XCTAssertEqual(try shellOut(to: .readFile(at: filePath)).stdout, "Hello again")
    }

    func testArgumentQuoting() throws {
        XCTAssertEqual(try shellOut(to: "echo".checked,
                                    arguments: ["foo ; echo bar".quoted]).stdout,
                       "foo ; echo bar")
        XCTAssertEqual(try shellOut(to: "echo".checked,
                                    arguments: ["foo ; echo bar".verbatim]).stdout,
                       "foo\nbar")
    }

    func test_Argument_ExpressibleByStringLiteral() throws {
        XCTAssertEqual(("foo" as Argument).string, "foo")
        XCTAssertEqual(("foo bar" as Argument).string, "'foo bar'")
    }

    func test_Argument_url() throws {
        XCTAssertEqual(Argument.url(.init(string: "https://example.com")!).string,
                       "https://example.com")
    }

    func test_git_tags() throws {
        // setup
        let tempDir = NSTemporaryDirectory().appending("test_stress_\(UUID())")
        defer {
            try? Foundation.FileManager.default.removeItem(atPath: tempDir)
        }
        let sampleGitRepoName = "ErrNo"
        let sampleGitRepoZipFile = fixturesDirectory()
            .appendingPathComponent("\(sampleGitRepoName).zip").path
        let path = "\(tempDir)/\(sampleGitRepoName)"
        try! Foundation.FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
        try! ShellOut.shellOut(to: .init(command: "unzip", arguments: [sampleGitRepoZipFile.quoted]), at: tempDir)

        // MUT
        XCTAssertEqual(try shellOut(to: try ShellOutCommand(command: "git", arguments: ["tag"]),
                                    at: path).stdout, """
                0.2.0
                0.2.1
                0.2.2
                0.2.3
                0.2.4
                0.2.5
                0.3.0
                0.4.0
                0.4.1
                0.4.2
                0.5.0
                0.5.1
                0.5.2
                v0.0.1
                v0.0.2
                v0.0.3
                v0.0.4
                v0.0.5
                v0.1.0
                """)
    }

    func test_git_tags_2() throws {
        // setup
        let tempDir = NSTemporaryDirectory().appending("test_stress_\(UUID())")
        defer {
            try? Foundation.FileManager.default.removeItem(atPath: tempDir)
        }
        let sampleGitRepoName = "ErrNo"
        let sampleGitRepoZipFile = fixturesDirectory()
            .appendingPathComponent("\(sampleGitRepoName).zip").path
        let path = "\(tempDir)/\(sampleGitRepoName)"
        try! Foundation.FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
        try! ShellOut.shellOut(to: .init(command: "unzip", arguments: [sampleGitRepoZipFile.quoted]), at: tempDir)

        // MUT
        XCTAssertEqual(try shellOut2(to: "git", arguments: ["tag"], at: path).stdout, """
                0.2.0
                0.2.1
                0.2.2
                0.2.3
                0.2.4
                0.2.5
                0.3.0
                0.4.0
                0.4.1
                0.4.2
                0.5.0
                0.5.1
                0.5.2
                v0.0.1
                v0.0.2
                v0.0.3
                v0.0.4
                v0.0.5
                v0.1.0
                """)
    }
}

extension ShellOutTests {
    func fixturesDirectory(path: String = #file) -> URL {
        let url = URL(fileURLWithPath: path)
        let testsDir = url.deletingLastPathComponent()
        return testsDir.appendingPathComponent("Fixtures")
    }
}
