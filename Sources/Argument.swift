public enum Argument {
    case safe(SafeString)
    case quoted(QuotedString)
    case verbatim(String)

    init(safe string: String) throws {
        self = try .safe(.init(string))
    }

    init(_ string: SafeString) {
        self = .safe(string)
    }

    init(quoted string: String) {
        self = .quoted(.init(string))
    }

    init(verbatim string: String) {
        self = .verbatim(string)
    }

    var string: String {
        switch self {
            case let .safe(value):
                return value.value
            case let .quoted(value):
                return value.quoted
            case let .verbatim(string):
                return string
        }
    }
}


extension String {
    var quoted: Argument { .init(quoted: self) }
    var verbatim: Argument { .init(verbatim: self) }
}


extension Array<String> {
    var quoted: [Argument] { map(\.quoted) }

    @available(*, deprecated)
    func safe() throws -> [Argument] { try map(Argument.init(safe:)) }

    var verbatim: [Argument] { map(\.verbatim) }
}
