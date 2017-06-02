/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - API

/**
 *  Run a shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
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
    let process = Process()
    let command = "cd \"\(path)\" && \(command) \(arguments.joined(separator: " "))"
    return try process.launchBash(with: command, outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a series of shell commands using Bash
 *
 *  - parameter commands: The commands to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `FileHandle` that any output (STDOUT) should be redirected to
 *  - parameter errorHandle: Any `FileHandle` that any error output (STDERR) should be redirected to
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

// Error type thrown by the `shellOut()` function, in case the given command failed
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

// MARK: - Private

private extension Process {
    @discardableResult func launchBash(with command: String, outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        var outputData = Data()
        var errorData = Data()

        let stdoutHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            outputData.append(data)
            outputHandle?.write(data)
        }

        let stderrHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            errorData.append(data)
            errorHandle?.write(data)
        }

        let outputPipe = Pipe()
        standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = stdoutHandler

        let errorPipe = Pipe()
        standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = stderrHandler

        launch()
        waitUntilExit()

        outputHandle?.closeFile()
        errorHandle?.closeFile()

        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

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

private extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }

        guard !output.hasSuffix("\n") else {
            let outputLength = output.distance(from: output.startIndex, to: output.endIndex)
            return output.substring(to: output.index(output.startIndex, offsetBy: outputLength - 1))
        }

        return output

    }
}
