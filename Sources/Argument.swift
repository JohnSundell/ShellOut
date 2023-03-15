public enum Argument {
    case quoted(QuotedString)
    case verbatim(String)

    public init(quoted string: String) {
        self = .quoted(.init(string))
    }

    public init(verbatim string: String) {
        self = .verbatim(string)
    }

    public var string: String {
        switch self {
            case let .quoted(value):
                return value.quoted
            case let .verbatim(string):
                return string
        }
    }
}


extension String {
    public var quoted: Argument { .init(quoted: self) }
    public var verbatim: Argument { .init(verbatim: self) }
}


extension Array<String> {
    public var quoted: [Argument] { map(\.quoted) }
    public var verbatim: [Argument] { map(\.verbatim) }
}
