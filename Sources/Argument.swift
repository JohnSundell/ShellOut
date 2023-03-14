public enum Argument {
    case quoted(QuotedString)
    case verbatim(String)

    init(quoted string: String) {
        self = .quoted(.init(string))
    }

    init(verbatim string: String) {
        self = .verbatim(string)
    }

    var string: String {
        switch self {
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
    var verbatim: [Argument] { map(\.verbatim) }
}
