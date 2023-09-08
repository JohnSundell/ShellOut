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
 *  Run a shell command
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
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
 *  Run a pre-defined shell command
 *
 *  - parameter command: The command to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
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

