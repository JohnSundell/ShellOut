/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Logging
import TSCBasic
import XCTest
@testable import ShellOut

final class ShellOutTests: XCTestCase {
    static var temporaryDirectoryUrl: URL!
    static var logger: Logger!
    
    override class func setUp() {
        XCTAssert(isLoggingConfigured)
        self.logger = .init(label: "test")
        // This is technically a misuse of the `withTemporaryDirectory()` utility, but there's no equivalent of
        // the `TemporaryFile` API for drectories and this is (much) easier than directly invoking `mkdtemp(3)`.
        // This is done in the class setUp rather than the instance method so it happens only once per test run,
        // rather than for each single test.
        self.temporaryDirectoryUrl = try! withTemporaryDirectory(prefix: "ShellOutTests", removeTreeOnDeinit: false, { $0.asURL })
    }
    
    override class func tearDown() {
        try? FileManager.default.removeItem(at: self.temporaryDirectoryUrl)
    }
    
    var logger: Logger { Self.logger }
    var tempUrl: URL { Self.temporaryDirectoryUrl }
    func tempUrl(filename: String) -> URL { Self.temporaryDirectoryUrl.appendingPathComponent(filename, isDirectory: false) }
    func tempUrl(directory: String) -> URL { Self.temporaryDirectoryUrl.appendingPathComponent(directory, isDirectory: true) }
    
    func test_appendArguments() throws {
        var cmd = ShellOutCommand(command: "foo")
        XCTAssertEqual(cmd.description, "foo")
        cmd.append(arguments: [";", "bar"])
        XCTAssertEqual(cmd.description, "foo ; bar" )
        cmd.append(arguments: ["> baz"])
        XCTAssertEqual(cmd.description, "foo ; bar > baz" )
    }

    func test_appendingArguments() throws {
        let cmd = ShellOutCommand(command: "foo")
        XCTAssertEqual(
            cmd.appending(arguments: [";", "bar"]).description,
            "foo ; bar"
        )
        XCTAssertEqual(
            cmd.appending(arguments: [";", "bar"])
                .appending(arguments: ["> baz"])
                .description,
            "foo ; bar > baz"
        )
    }

    func testWithoutArguments() async throws {
        let uptime = try await shellOut(to: "uptime", logger: logger).stdout
        XCTAssertTrue(uptime.contains("load average"))
    }

    func testWithArguments() async throws {
        let echo = try await shellOut(to: "echo", arguments: ["Hello world"], logger: logger).stdout
        XCTAssertEqual(echo, "Hello world")
    }

    func testSingleCommandAtPath() async throws {
        try await shellOut(
            to: "bash",
            arguments: ["-c", #"echo Hello > "\#(tempUrl(filename: "ShellOutTests-SingleCommand.txt").path)""#],
            logger: logger
        )

        let textFileContent = try await shellOut(
            to: "cat",
            arguments:  ["ShellOutTests-SingleCommand.txt"],
            at: tempUrl.path,
            logger: logger
        ).stdout

        XCTAssertEqual(textFileContent, "Hello")
    }

    func testSingleCommandAtPathContainingSpace() async throws {
        try await shellOut(to: "mkdir",
                     arguments: ["-p", "ShellOut Test Folder"],
                     at: tempUrl.path,
                     logger: logger)
        let testFolderUrl = tempUrl(directory: "ShellOut Test Folder")
        try await shellOut(to: "bash", arguments: ["-c", "echo Hello > File"],
                     at: testFolderUrl.path,
                     logger: logger)

        let output = try await shellOut(
            to: "cat",
            arguments: [testFolderUrl.appendingPathComponent("File", isDirectory: false).path],
            logger: logger).stdout
        XCTAssertEqual(output, "Hello")
    }

    func testSingleCommandAtPathContainingTilde() async throws {
        let homeContents = try await shellOut(to: "ls", arguments: ["-a"], at: "~", logger: logger).stdout
        XCTAssertFalse(homeContents.isEmpty)
    }

    func testThrowingError() async {
        await XCTAssertThrowsErrorAsync(try await shellOut(to: .bash(arguments: ["cd notADirectory"]), logger: logger)) {
            guard let error = $0 as? ShellOutError else {
                return XCTFail("Expected ShellOutError, got \(String(reflecting: $0))")
            }
            XCTAssertTrue(error.message.contains("notADirectory"))
            XCTAssertTrue(error.output.isEmpty)
            XCTAssertTrue(error.terminationStatus != 0)
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

    func testCapturingOutputWithHandle() async throws {
        let pipe = Pipe()
        let output = try await shellOut(to: "echo",
                                  arguments: ["Hello"],
                                  logger: logger,
                                  outputHandle: pipe.fileHandleForWriting).stdout
        let capturedData = pipe.fileHandleForReading.readDataToEndOfFile()
        XCTAssertEqual(output, "Hello")
        XCTAssertEqual(output + "\n", String(data: capturedData, encoding: .utf8))
    }

    func testCapturingErrorWithHandle() async throws {
        let pipe = Pipe()

        await XCTAssertThrowsErrorAsync(
            try await shellOut(to: .bash(arguments: ["cd notADirectory"]), logger: logger, errorHandle: pipe.fileHandleForWriting)
        ) {
            guard let error = $0 as? ShellOutError else {
                return XCTFail("Expected ShellOutError, got \(String(reflecting: $0))")
            }
            XCTAssertTrue(error.message.contains("notADirectory"))
            XCTAssertTrue(error.output.isEmpty)
            XCTAssertTrue(error.terminationStatus != 0)

            let capturedData = pipe.fileHandleForReading.readDataToEndOfFile()
            XCTAssertEqual(error.message + "\n", String(decoding: capturedData, as: UTF8.self))
        }
    }

    func testGitCommands() async throws {
        // Setup & clear state
        try await shellOut(
            to: "rm",
            arguments: ["-rf", "GitTestOrigin"],
            at: tempUrl.path,
            logger: logger
        )
        try await shellOut(
            to: "rm",
            arguments: ["-rf", "GitTestClone"],
            at: tempUrl.path,
            logger: logger
        )

        // Create a origin repository and make a commit with a file
        let originDir = tempUrl(directory: "GitTestOrigin")
        try await shellOut(to: .createFolder(named: "GitTestOrigin"), at: tempUrl.path, logger: logger)
        try await shellOut(to: .gitInit(), at: originDir.path, logger: logger)
        try await shellOut(to: .createFile(named: "Test", contents: "Hello world"), at: originDir.path, logger: logger)
        try await shellOut(to: "git", arguments: ["add", "."], at: originDir.path, logger: logger)
        try await shellOut(to: .gitCommit(message: "Commit"), at: originDir.path, logger: logger)

        // Clone to a new repository and read the file
        let cloneDir = tempUrl(directory: "GitTestClone")
        try await shellOut(to: .gitClone(url: originDir, to: "GitTestClone"), at: tempUrl.path, logger: logger)

        let fileUrl = cloneDir.appendingPathComponent("Test", isDirectory: false)
        await XCTAssertEqualAsync(try await shellOut(to: .readFile(at: fileUrl.path), logger: logger).stdout, "Hello world")

        // Make a new commit in the origin repository
        try await shellOut(to: .createFile(named: "Test", contents: "Hello again"), at: originDir.path, logger: logger)
        try await shellOut(to: .gitCommit(message: "Commit"), at: originDir.path, logger: logger)

        // Pull the commit in the clone repository and read the file again
        try await shellOut(to: .gitPull(), at: cloneDir.path, logger: logger)
        await XCTAssertEqualAsync(try await shellOut(to: .readFile(at: fileUrl.path), logger: logger).stdout, "Hello again")
    }

    func testBash() async throws {
        // Without explicit -c parameter
        await XCTAssertEqualAsync(try await shellOut(to: .bash(arguments: ["echo", "foo"]), logger: logger).stdout,
                                  "foo")
        // With explicit -c parameter
        await XCTAssertEqualAsync(try await shellOut(to: .bash(arguments: ["-c", "echo", "foo"]), logger: logger).stdout,
                                  "foo")
    }

    func testBashArgumentQuoting() async throws {
        await XCTAssertEqualAsync(try await shellOut(to: .bash(arguments: ["echo",
                                                                           "foo ; echo bar".quoted]), logger: logger).stdout,
                                  "foo ; echo bar")
        await XCTAssertEqualAsync(try await shellOut(to: .bash(arguments: ["echo",
                                                                           "foo ; echo bar".verbatim]), logger: logger).stdout,
                                  "foo\nbar")
    }

    func test_Argument_ExpressibleByStringLiteral() throws {
        XCTAssertEqual(("foo" as Argument).description, "foo")
        XCTAssertEqual(("foo bar" as Argument).description, "'foo bar'")
    }

    func test_Argument_url() throws {
        XCTAssertEqual(Argument.url(.init(string: "https://example.com")!).description,
                       "https://example.com")
    }

    func test_git_tags() async throws {
        // setup
        let tempDir = tempUrl(directory: "test_stress_\(UUID())")
        let sampleGitRepoName = "ErrNo"
        let sampleGitRepoZipFile = fixturesDirectory().appendingPathComponent(sampleGitRepoName, isDirectory: false).appendingPathExtension("zip").path
        let sampleGitRepoDir = tempDir.appendingPathComponent(sampleGitRepoName, isDirectory: true)

        try Foundation.FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false, attributes: nil)
        try await ShellOut.shellOut(to: .init(command: "unzip", arguments: [sampleGitRepoZipFile]), at: tempDir.path, logger: logger)

        // MUT
        await XCTAssertEqualAsync(
            try await shellOut(to: ShellOutCommand(command: "git", arguments: ["tag"]), at: sampleGitRepoDir.path, logger: logger).stdout,
            """
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
    func fixturesDirectory(path: String = #filePath) -> URL {
        let url = URL(fileURLWithPath: path, isDirectory: false)
        let testsDir = url.deletingLastPathComponent()
        return testsDir.appendingPathComponent("Fixtures", isDirectory: true)
    }
}
