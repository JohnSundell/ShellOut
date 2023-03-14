import ShellQuote


public struct SafeString {
    public var value: String

    public init(_ value: String) throws {
        guard !ShellQuote.hasUnsafeContent(value) else {
            throw ShellOutCommand.Error(message: "Command must not contain characters that require quoting, was: \(value)")
        }
        self.value = value
    }

    public init(unchecked value: String) {
        self.value = value
    }
}

extension SafeString: CustomStringConvertible {
    public var description: String { value }
}
