/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Dispatch
import Logging
import TSCBasic
import Algorithms

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
    logger: Logger? = nil,
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil,
    environment: [String : String]? = nil
) async throws -> (stdout: String, stderr: String) {
    try await TSCBasic.Process.launch(
        command: command,
        arguments: arguments,
        logger: logger,
        outputHandle: outputHandle,
        errorHandle: errorHandle,
        environment: environment,
        at: path == "." ? nil :
            (path == "~" ? TSCBasic.localFileSystem.homeDirectory.pathString :
            (path.starts(with: "~/") ? "\(TSCBasic.localFileSystem.homeDirectory.pathString)/\(path.dropFirst(2))" :
            path))
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
    logger: Logger? = nil,
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil,
    environment: [String : String]? = nil
) async throws -> (stdout: String, stderr: String) {
    try await shellOut(
        to: command.command,
        arguments: command.arguments,
        at: path,
        logger: logger,
        outputHandle: outputHandle,
        errorHandle: errorHandle,
        environment: environment
    )
}


public extension ShellOutCommand {
    static func bash(arguments: [Argument]) -> Self {
        let arguments = arguments.first == "-c" ? Array(arguments.dropFirst()) : arguments
        return .init(command: "bash", arguments: ["-c", arguments.map(\.description).joined(separator: " ")])
    }
}

/// Git commands
public extension ShellOutCommand {
    /// Initialize a git repository
    static func gitInit() -> ShellOutCommand {
        .init(command: "git", arguments: ["init"])
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
            .appending(arguments: ["commit", "-a", "-m", "\(message.quoted)"])

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
            .appending(arguments: ["submodule update"])

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
        var command = ShellOutCommand(command: "git",
                                      arguments: ["checkout", branch])

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    private static func git(allowingPrompt: Bool) -> Self {
        allowingPrompt
        ? .init(command: "git")
        : .init(command: "env",
                arguments: ["GIT_TERMINAL_PROMPT=0", "git"])

    }
}

/// File system commands
public extension ShellOutCommand {
    /// Create a folder with a given name
    static func createFolder(named name: String) -> ShellOutCommand {
        .init(command: "mkdir", arguments: [name])
    }

    /// Create a file with a given name and contents (will overwrite any existing file with the same name)
    static func createFile(named name: String, contents: String) -> ShellOutCommand {
        .bash(arguments: ["-c", #"echo \#(contents.quoted) > \#(name.quoted)"#.verbatim])
    }

    /// Move a file from one path to another
    static func moveFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(command: "mv", arguments: [originPath, targetPath])
    }
    
    /// Copy a file from one path to another
    static func copyFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(command: "cp", arguments: [originPath, targetPath])
    }
    
    /// Remove a file
    static func removeFile(from path: String, arguments: [String] = ["-f"]) -> ShellOutCommand {
        .init(command: "rm", arguments: arguments + [path])
    }

    /// Open a file using its designated application
    static func openFile(at path: String) -> ShellOutCommand {
        .init(command: "open", arguments: [path])
    }

    /// Read a file as a string
    static func readFile(at path: String) -> ShellOutCommand {
        .init(command: "cat", arguments: [path])
    }

    /// Create a symlink at a given path, to a given target
    static func createSymlink(to targetPath: String, at linkPath: String) -> ShellOutCommand {
        .init(command: "ln", arguments: ["-s", targetPath, linkPath])
    }

    /// Expand a symlink at a given path, returning its target path
    static func expandSymlink(at path: String) -> ShellOutCommand {
        .init(command: "readlink", arguments: [path])
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
        .init(command: "swift",
              arguments: ["package", "init", "--type", "\(type)"])
    }

    /// Update all Swift package dependencies
    static func updateSwiftPackages() -> ShellOutCommand {
        .init(command: "swift", arguments: ["package", "update"])
    }

    /// Build a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func buildSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(command: "swift",
              arguments: ["build -c \(configuration)"])
    }

    /// Test a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func testSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(command: "swift",
              arguments: ["test", "-c", "\(configuration)"])
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

// MARK: - Private

private extension TSCBasic.Process {
    @discardableResult static func launch(
        command: String,
        arguments: [String],
        logger: Logger? = nil,
        outputHandle: FileHandle? = nil,
        errorHandle: FileHandle? = nil,
        environment: [String : String]? = nil,
        at: String? = nil
    ) async throws -> (stdout: String, stderr: String) {
        let process = try Self.init(
            arguments: [command] + arguments,
            environment: environment ?? ProcessEnv.vars,
            workingDirectory: at.map { try .init(validating: $0) } ?? TSCBasic.localFileSystem.currentWorkingDirectory ?? .root,
            outputRedirection: .collect(redirectStderr: false),
            startNewProcessGroup: false,
            loggingHandler: nil
        )
        
        try process.launch()
        
        let result = try await process.waitUntilExit()
        
        try outputHandle?.write(contentsOf: (try? result.output.get()) ?? [])
        try outputHandle?.close()
        try errorHandle?.write(contentsOf: (try? result.stderrOutput.get()) ?? [])
        try errorHandle?.close()
        
        guard case .terminated(code: let code) = result.exitStatus, code == 0 else {
            let code: Int32
            switch result.exitStatus {
            case .terminated(code: let termCode): code = termCode
            case .signalled(signal: let sigNo): code = -sigNo
            }
            throw ShellOutError(
                terminationStatus: code,
                errorData: Data((try? result.stderrOutput.get()) ?? []),
                outputData: Data((try? result.output.get()) ?? [])
            )
        }
        return try (
            stdout: String(result.utf8Output().trimmingSuffix(while: \.isNewline)),
            stderr: String(result.utf8stderrOutput().trimmingSuffix(while: \.isNewline))
        )
    }
}

private extension Data {
    func shellOutput() -> String {
        let output = String(decoding: self, as: UTF8.self)

        guard !output.hasSuffix("\n") else {
            return String(output.dropLast())
        }

        return output

    }
}
