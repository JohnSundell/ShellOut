import Foundation

public enum Argument: Equatable {
    case quoted(QuotedString)
    case verbatim(String)

    public init(quoted string: some StringProtocol) {
        self = .quoted(.init(.init(string)))
    }

    public init(verbatim string: some StringProtocol) {
        self = .verbatim(.init(string))
    }
}

extension Argument: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .quoted(.init(value))
    }
}

extension Argument: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .quoted(value):
                return value.quoted
            case let .verbatim(string):
                return string
        }
    }
}

extension Argument {
    public static func url(_ url: URL) -> Self { url.absoluteString.verbatim }
}


extension StringProtocol {
    public var quoted: Argument { .init(quoted: self) }
    public var verbatim: Argument { .init(verbatim: self) }
}

extension Sequence<StringProtocol> {
    public var quoted: [Argument] { map(\.quoted) }
    public var verbatim: [Argument] { map(\.verbatim) }
}
