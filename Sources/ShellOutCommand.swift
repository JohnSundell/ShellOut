/// Structure used to pre-define commands for use with ShellOut
public struct ShellOutCommand: Equatable {
    /// The string that makes up the command that should be run on the command line
    public var command: String

    public var arguments: [String]

    /// Initialize a value using a string that makes up the underlying command
    public init(command: String, arguments: [String] = []) {
        self.command = command
        self.arguments = arguments
    }

    public func appending(arguments newArguments: [String]) -> Self {
        .init(command: command, arguments: arguments + newArguments)
    }

    public func appending(argument: String) -> Self {
        appending(arguments: [argument])
    }

    public mutating func append(arguments newArguments: [String]) {
        self.arguments = self.arguments + newArguments
    }

    public mutating func append(argument: String) {
        append(arguments: [argument])
    }
}

extension ShellOutCommand: CustomStringConvertible {
    public var description: String {
        ([command] + arguments).joined(separator: " ")
    }
}
