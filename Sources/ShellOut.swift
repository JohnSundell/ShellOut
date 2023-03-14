/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Dispatch
import ShellQuote

// MARK: - API

/**
 *  Run a shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter process: Which process to use to perform the command (default: A new one)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter environment: The environment for the command.
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "mkdir", arguments: ["NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(
    to command: String,
    arguments: [String] = [],
    at path: String = ".",
    process: Process = .init(),
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil,
    environment: [String : String]? = nil,
    quoteArguments: Bool = true
) throws -> String {
    guard !ShellQuote.hasUnsafeContent(command) else {
        throw ShellOutCommand.Error(message: "Command must not contain characters that require quoting, was: \(command)")
    }
    let arguments = quoteArguments ? arguments.map(ShellQuote.quote) : arguments
    let command = "cd \(path.escapingSpaces) && \(command) \(arguments.joined(separator: " "))"

    return try process.launchBash(
        with: command,
        outputHandle: outputHandle,
        errorHandle: errorHandle,
        environment: environment
    )
}

/**
 *  Run a pre-defined shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter process: Which process to use to perform the command (default: A new one)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
 *  - parameter environment: The environment for the command.
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: .gitCommit(message: "Commit"), at: "~/CurrentFolder")`
 *
 *  See `ShellOutCommand` for more info.
 */
@discardableResult public func shellOut(
    to command: ShellOutCommand,
    at path: String = ".",
    process: Process = .init(),
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil,
    environment: [String : String]? = nil
) throws -> String {
    try shellOut(
        to: command.command,
        arguments: command.arguments,
        at: path,
        process: process,
        outputHandle: outputHandle,
        errorHandle: errorHandle,
        environment: environment,
        quoteArguments: false
    )
}

/// Structure used to pre-define commands for use with ShellOut
public struct ShellOutCommand {
    /// The string that makes up the command that should be run on the command line
    public var command: String

    public var arguments: [String]

    /// Initialize a value using a string that makes up the underlying command
    public init(command: String, arguments: [String] = [], quoteArguments: Bool = true) throws {
        guard !ShellQuote.hasUnsafeContent(command) else {
            throw ShellOutCommand.Error(message: "Command must not contain characters that require quoting, was: \(command)")
        }

        self.command = command
        self.arguments = quoteArguments ? arguments.map(ShellQuote.quote) : arguments
    }

    public init(safeCommand: String, arguments: [String] = [], quoteArguments: Bool = true) {
        self.command = safeCommand
        self.arguments = quoteArguments ? arguments.map(ShellQuote.quote) : arguments
    }

    var string: String { ([command] + arguments).joined(separator: " ") }

    func appending(arguments: [String], quoteArguments: Bool = true) -> Self {
        .init(
            safeCommand: self.command,
            arguments: self.arguments + (quoteArguments ? arguments.map(ShellQuote.quote) : arguments),
            quoteArguments: false
        )
    }

    func appending(argument: String, quoteArguments: Bool = true) -> Self {
        appending(arguments: [argument], quoteArguments: quoteArguments)
    }

    mutating func append(arguments: [String], quoteArguments: Bool = true) {
        self.arguments = self.arguments + (quoteArguments ? arguments.map(ShellQuote.quote) : arguments)
    }

    mutating func append(argument: String, quoteArguments: Bool = true) {
        append(arguments: [argument], quoteArguments: quoteArguments)
    }
}

/// Git commands
public extension ShellOutCommand {
    /// Initialize a git repository
    static func gitInit() -> ShellOutCommand {
        return ShellOutCommand(safeCommand: "git", arguments: ["init"])
    }

    /// Clone a git repository at a given URL
    static func gitClone(url: URL, to path: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["clone", url.absoluteString])

        path.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Create a git commit with a given message (also adds all untracked file to the index)
    static func gitCommit(message: String, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["add . && git commit -a -m"], quoteArguments: false)
        command.append(argument: message)

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Perform a git push
    static func gitPush(remote: String? = nil, branch: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["push"])
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Perform a git pull
    static func gitPull(remote: String? = nil, branch: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["pull"])
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Run a git submodule update
    static func gitSubmoduleUpdate(initializeIfNeeded: Bool = true, recursive: Bool = true, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["submodule update"], quoteArguments: false)

        if initializeIfNeeded {
            command.append(argument: "--init")
        }

        if recursive {
            command.append(argument: "--recursive")
        }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Checkout a given git branch
    static func gitCheckout(branch: String, quiet: Bool = true) -> ShellOutCommand {
        var command = ShellOutCommand(safeCommand: "git", arguments: ["checkout", branch])

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    private static func git(allowingPrompt: Bool) -> Self {
        allowingPrompt
        ? .init(safeCommand: "git")
        : .init(safeCommand: "env", arguments: ["GIT_TERMINAL_PROMPT=0", "git"])

    }
}

/// File system commands
public extension ShellOutCommand {
    /// Create a folder with a given name
    static func createFolder(named name: String) -> ShellOutCommand {
        .init(safeCommand: "mkdir", arguments: [name])
    }

    /// Create a file with a given name and contents (will overwrite any existing file with the same name)
    static func createFile(named name: String, contents: String) -> ShellOutCommand {
        .init(safeCommand: "echo", arguments: [contents])
        .appending(argument: ">", quoteArguments: false)
        .appending(argument: name)
    }

    /// Move a file from one path to another
    static func moveFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(safeCommand: "mv", arguments: [originPath, targetPath])
    }
    
    /// Copy a file from one path to another
    static func copyFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(safeCommand: "cp", arguments: [originPath, targetPath])
    }
    
    /// Remove a file
    static func removeFile(from path: String, arguments: [String] = ["-f"]) -> ShellOutCommand {
        .init(safeCommand: "rm", arguments: arguments + [path])
    }

    /// Open a file using its designated application
    static func openFile(at path: String) -> ShellOutCommand {
        .init(safeCommand: "open", arguments: [path])
    }

    /// Read a file as a string
    static func readFile(at path: String) -> ShellOutCommand {
        .init(safeCommand: "cat", arguments: [path])
    }

    /// Create a symlink at a given path, to a given target
    static func createSymlink(to targetPath: String, at linkPath: String) -> ShellOutCommand {
        .init(safeCommand: "ln", arguments: ["-s", targetPath, linkPath])
    }

    /// Expand a symlink at a given path, returning its target path
    static func expandSymlink(at path: String) -> ShellOutCommand {
        .init(safeCommand: "readlink", arguments: [path])
    }
}

/// Marathon commands
public extension ShellOutCommand {
    /// Run a Marathon Swift script
    static func runMarathonScript(at path: String, arguments: [String] = []) -> ShellOutCommand {
        .init(safeCommand: "marathon", arguments: ["run", path] + arguments)
    }

    /// Update all Swift packages managed by Marathon
    static func updateMarathonPackages() -> ShellOutCommand {
        .init(safeCommand: "marathon", arguments: ["update"])
    }
}

/// Swift Package Manager commands
public extension ShellOutCommand {
    /// Enum defining available package types when using the Swift Package Manager
    enum SwiftPackageType: String {
        case library
        case executable
    }

    /// Enum defining available build configurations when using the Swift Package Manager
    enum SwiftBuildConfiguration: String {
        case debug
        case release
    }

    /// Create a Swift package with a given type (see SwiftPackageType for options)
    static func createSwiftPackage(withType type: SwiftPackageType = .library) -> ShellOutCommand {
        .init(safeCommand: "swift",
              arguments: ["package init --type \(type)"],
              quoteArguments: false)
    }

    /// Update all Swift package dependencies
    static func updateSwiftPackages() -> ShellOutCommand {
        .init(safeCommand: "swift", arguments: ["package", "update"])
    }

    /// Generate an Xcode project for a Swift package
    static func generateSwiftPackageXcodeProject() -> ShellOutCommand {
        .init(safeCommand: "swift", arguments: ["package", "generate-xcodeproj"])
    }

    /// Build a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func buildSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(safeCommand: "swift",
              arguments: ["build -c \(configuration)"],
              quoteArguments: false)
    }

    /// Test a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func testSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(safeCommand: "swift",
              arguments: ["test -c \(configuration)"],
              quoteArguments: false)
    }
}

/// Fastlane commands
public extension ShellOutCommand {
    /// Run Fastlane using a given lane
    static func runFastlane(usingLane lane: String) -> ShellOutCommand {
        .init(safeCommand: "fastlane", arguments: [lane])
    }
}

/// CocoaPods commands
public extension ShellOutCommand {
    /// Update all CocoaPods dependencies
    static func updateCocoaPods() -> ShellOutCommand {
        .init(safeCommand: "pod", arguments: ["update"])
    }

    /// Install all CocoaPods dependencies
    static func installCocoaPods() -> ShellOutCommand {
        .init(safeCommand: "pod", arguments: ["install"])
    }
}

/// Error type thrown by the `shellOut()` function, in case the given command failed
public struct ShellOutError: Swift.Error {
    /// The termination status of the command that was run
    public let terminationStatus: Int32
    /// The error message as a UTF8 string, as returned through `STDERR`
    public var message: String { return errorData.shellOutput() }
    /// The raw error buffer data, as returned through `STDERR`
    public let errorData: Data
    /// The raw output buffer data, as retuned through `STDOUT`
    public let outputData: Data
    /// The output of the command as a UTF8 string, as returned through `STDOUT`
    public var output: String { return outputData.shellOutput() }
}

extension ShellOutError: CustomStringConvertible {
    public var description: String {
        return """
               ShellOut encountered an error
               Status code: \(terminationStatus)
               Message: "\(message)"
               Output: "\(output)"
               """
    }
}

extension ShellOutError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

extension ShellOutCommand {
    // TODO: consolidate with ShellOutError
    struct Error: Swift.Error {
        var message: String
    }
}

// MARK: - Private

private extension Process {
    @discardableResult func launchBash(with command: String, outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil, environment: [String : String]? = nil) throws -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        if let environment = environment {
            self.environment = environment
        }

        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")

        var outputData = Data()
        var errorData = Data()

        let outputPipe = Pipe()
        standardOutput = outputPipe

        let errorPipe = Pipe()
        standardError = errorPipe

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                outputData.append(data)
                outputHandle?.write(data)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                errorData.append(data)
                errorHandle?.write(data)
            }
        }
        #endif

        launch()

        #if os(Linux)
        outputQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif

        waitUntilExit()

        if let handle = outputHandle, !handle.isStandard {
            handle.closeFile()
        }

        if let handle = errorHandle, !handle.isStandard {
            handle.closeFile()
        }

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        #endif

        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if terminationStatus != 0 {
                throw ShellOutError(
                    terminationStatus: terminationStatus,
                    errorData: errorData,
                    outputData: outputData
                )
            }

            return outputData.shellOutput()
        }
    }
}

private extension FileHandle {
    var isStandard: Bool {
        return self === FileHandle.standardOutput ||
            self === FileHandle.standardError ||
            self === FileHandle.standardInput
    }
}

private extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }

        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            return String(output[..<endIndex])
        }

        return output

    }
}

private extension String {
    var escapingSpaces: String {
        return replacingOccurrences(of: " ", with: "\\ ")
    }

    func appending(argument: String) -> String {
        return "\(self) \"\(argument)\""
    }

    func appending(arguments: [String]) -> String {
        return appending(argument: arguments.joined(separator: "\" \""))
    }

    mutating func append(argument: String) {
        self = appending(argument: argument)
    }

    mutating func append(arguments: [String]) {
        self = appending(arguments: arguments)
    }
}
