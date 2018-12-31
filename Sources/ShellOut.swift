/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Dispatch

// MARK: - Asynchronously

public typealias Completion = (_ inner: () throws -> String) -> Void

/**
 *  Run a shell command asynchronously using Bash
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter completion: The outcome of the execution.
 *
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "echo", arguments: ["Hello World"]) { (completion) in
 *      do {
 *          let output = try completion()
 *          XCTAssertEqual(output, "Hello world")
 *      } catch {
 *          XCTFail("Command failed to execute")
 *      }
 *  }`
 */
public func shellOut(to command: String,
                      arguments: [String] = [],
                        at path: String = ".",
      withCompletion completion: @escaping Completion) {
    
    let command = "cd \(path.escapingSpaces) && \(command) \(arguments.joined(separator: " "))"
    let process = Process.makeBashProcess(withArguments: ["-c", command])
    
    let shellOutQueue = DispatchQueue(label: "shell-out-queue")
    
    shellOutQueue.async {
        process.launchBash(withCompletion: completion)
    }
}

/**
 *  Run a series of shell commands asynchronously using Bash
 *
 *  - parameter commands: The commands to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter completion: The outcome of the execution.
 *
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "echo", arguments: ["Hello World"]) { (completion) in
 *      do {
 *          let output = try completion()
 *          XCTAssertEqual(output, "Hello world")
 *      } catch {
 *          XCTFail("Command failed to execute")
 *      }
 *  }`
 */
public func shellOut(to commands: [String],
                       arguments: [String] = [],
                         at path: String = ".",
       withCompletion completion: @escaping Completion) {
    let command = commands.joined(separator: " && ")
    shellOut(to: command, arguments: arguments, at: path, withCompletion: completion)
}

/**
 *  Run a pre-defined shell command asynchronously using Bash
 *
 *  - parameter command: The command to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: .gitCommit(message: "Commit"), at: "~/CurrentFolder")`
 *  For example: `shellOut(to: .gitCommit(message: "Commit"), at: "~/CurrentFolder") { (completion) in
 *      do {
 *          _ = try completion()
 *      } catch {
 *          XCTFail("Command failed to execute")
 *      }
 *  }`
 *  See `ShellOutCommand` for more info.
 */
public func shellOut(to command: ShellOutCommand,
                        at path: String = ".",
      withCompletion completion: @escaping Completion) {
    shellOut(to: command.string, at: path, withCompletion: completion)
}

// MARK: - Synchronously

/**
 *  Run a shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
 *              (at the moment this is only supported on macOS)
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "mkdir", arguments: ["NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(to command: String,
                                         arguments: [String] = [],
                                           at path: String = ".",
                                      outputHandle: FileHandle? = nil,
                                       errorHandle: FileHandle? = nil) throws -> String {
    let command = "cd \(path.escapingSpaces) && \(command) \(arguments.joined(separator: " "))"
    let process = Process.makeBashProcess(withArguments: ["-c", command])
    return try process.launchBash(outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a series of shell commands using Bash
 *
 *  - parameter commands: The commands to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
 *              (at the moment this is only supported on macOS)
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: ["mkdir NewFolder", "cd NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(to commands: [String],
                                        at path: String = ".",
                                        outputHandle: FileHandle? = nil,
                                        errorHandle: FileHandle? = nil) throws -> String {
    let command = commands.joined(separator: " && ")
    return try shellOut(to: command, at: path, outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a pre-defined shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: .gitCommit(message: "Commit"), at: "~/CurrentFolder")`
 *
 *  See `ShellOutCommand` for more info.
 */
@discardableResult public func shellOut(to command: ShellOutCommand,
                                        at path: String = ".",
                                        outputHandle: FileHandle? = nil,
                                        errorHandle: FileHandle? = nil) throws -> String {
    return try shellOut(to: command.string, at: path, outputHandle: outputHandle, errorHandle: errorHandle)
}
