import ShellQuote


public struct QuotedString: Equatable {
    public var unquoted: String
    public var quoted: String

    public init(_ value: String) {
        self.unquoted = value
        self.quoted = ShellQuote.quote(value)
    }
}


extension QuotedString: CustomStringConvertible {
    public var description: String { quoted }
}
