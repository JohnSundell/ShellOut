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
 *  - parameter outputHandle: The `FileHandle` where STDOUT should be redirected to
 *  - parameter errorHandle: The `FileHandle` where STDERR should be redirected to
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
                                       outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
    let process = Process()
    let command = "cd \"\(path)\" && \(command) \(arguments.joined(separator: " "))"
    return try process.launchBash(with: command, outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a series of shell commands using Bash
 *
 *  - parameter commands: The commands to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: The `FileHandle` where STDOUT should be redirected to
 *  - parameter errorHandle: The `FileHandle` where STDERR should be redirected to
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: ["mkdir NewFolder", "cd NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(to commands: [String], at path: String = ".", outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
    let command = commands.joined(separator: " && ")
    return try shellOut(to: command, at: path, outputHandle: outputHandle, errorHandle: errorHandle)
}

// Error type thrown by the `shellOut()` function, in case the given command failed
public struct ShellOutError: Swift.Error {
    /// The buffer data retuned by `STDERR`.
    public let stderr: Data
    /// The buffer data retuned by `STOUT`.
    public let stdout: Data
    /// The termination status of the command.
    public let terminationStatus: Int32
    /// The error message that was returned through `STDERR`
    public var message: String {
        return stderr.shellOutput() ?? ""
    }
    /// Any output that was put in `STDOUT` despite the error being thrown
    public var output: String {
        return stdout.shellOutput() ?? ""
    }
}

// MARK: - Private
private extension Process {

    private func closeHandle(_ handle: FileHandle?) {
        if let handle = handle {
            handle.closeFile()
        }
    }

    @discardableResult func launchBash(with command: String, outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> Data {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        var stdoutData = Data()
        var stderrData = Data()

        let stdoutHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            stdoutData.append(data)
            if let handler = outputHandle {
               handler.write(data)
            }
        }

        let stderrHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            stderrData.append(data)
            if let handler = errorHandle {
                handler.write(data)
            }
        }

        let outputPipe = Pipe()
        standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = stdoutHandler

        let errorPipe = Pipe()
        standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = stderrHandler

        launch()

        waitUntilExit()

        // This is needed to close the file handle at the end. See: `Pipe` documentation
        closeHandle(outputHandle)
        closeHandle(errorHandle)

        if terminationStatus != 0 {
            throw ShellOutError(stderr: stderrData, stdout: stdoutData, terminationStatus: terminationStatus)
        }

        FileHandle.standardError.readabilityHandler = nil
        FileHandle.standardOutput.readabilityHandler = nil

        return stdoutData
    }

    @discardableResult func launchBash(with command: String, outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
        return try launchBash(with: command, outputHandle: outputHandle, errorHandle: errorHandle).shellOutput() ?? ""
    }

}

private extension Data {
    func shellOutput() -> String? {
        guard let output = String(data: self, encoding: .utf8) else {
            return nil
        }

        guard !output.hasSuffix("\n") else {
            let outputLength = output.distance(from: output.startIndex, to: output.endIndex)
            return output.substring(to: output.index(output.startIndex, offsetBy: outputLength - 1))
        }

        return output

    }
}
