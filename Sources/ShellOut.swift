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
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "mkdir", arguments: "NewFolder")`
 */
@discardableResult public func shellOut(to command: String, arguments: [String] = []) throws -> String {
    let process = Process()
    let command = "\(command) \(arguments.joined(separator: " "))"
    return try process.launchBash(with: command)
}

// Error type thrown by the `shellOut()` function, in case the given command failed
public struct ShellOutError: Swift.Error {
    /// The error message that was returned through `STDERR`
    public let message: String
    /// Any output that was put in `STDOUT` despite the error being thrown
    public let output: String
}

// MARK: - Private

private extension Process {
    @discardableResult func launchBash(with command: String) throws -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        let outputPipe = Pipe()
        standardOutput = outputPipe

        let errorPipe = Pipe()
        standardError = errorPipe

        launch()

        let output = outputPipe.read() ?? ""
        let error = errorPipe.read()

        waitUntilExit()

        if let error = error {
            if !error.isEmpty {
                throw ShellOutError(message: error, output: output)
            }
        }

        return output
    }
}

private extension Pipe {
    func read() -> String? {
        let data = fileHandleForReading.readDataToEndOfFile()

        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        guard !output.hasSuffix("\n") else {
            let outputLength = output.distance(from: output.startIndex, to: output.endIndex)
            return output.substring(to: output.index(output.startIndex, offsetBy: outputLength - 1))
        }
        
        return output
    }
}

