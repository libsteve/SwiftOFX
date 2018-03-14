import Foundation

/// The representation of a raw unit of information from an OFX file.
enum Token {
  /// A key-value pair from the OFX file's header section.
  case header(key: String, value: String)

  /// A marker representing the beginning of some tagged nested data.
  case openTag(String)

  /// A marker representing the end of some tagged nested data section.
  case closeTag(String)

  /// The end of a line of text.
  case newline

  /// Raw text data within a header or tagged section.
  case content(String)
}

extension Token: Equatable {
  static func == (left: Token, right: Token) -> Bool {
    switch (left, right) {
    case let (.header(key: a, value: b), .header(key: x, value: y)): return a == x && b == y
    case let (.openTag(a), .openTag(b)): return a == b
    case let (.closeTag(a), .closeTag(b)): return a == b
    case (.newline, .newline): return true
    case let (.content(a), .content(b)): return a == b
    default: return false
    }
  }
}

extension Token {
  /// - note: This is an overload of the comparitor operator used by `case` statements.
  static func ~= (pattern: Token, sample: Token) -> Bool {
    switch (pattern, sample) {
    case (.header(key: _, value: _), .header(key: _, value: _)),
         (.openTag(_), .openTag(_)),
         (.closeTag(_), .closeTag(_)),
         (.newline, .newline),
         (.content(_), .content(_)):
      return true
    default:
      return false
    }
  }
}
