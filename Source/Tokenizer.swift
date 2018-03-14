import Foundation
import Reggie

struct Tokenizer: IteratorProtocol {
  private var lexer: Lexer<UnicodeScalar>
  private var readingBody: Bool = false

  private static let bodyTokenizers: [(NFA<UnicodeScalar>, (String) -> Token)] = [
    (openTag, {
      let characters = $0.dropFirst().dropLast()
      let result = String(characters).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      return .openTag(result)
    }),
    (closeTag, {
      let characters = $0.dropFirst().dropFirst().dropLast()
      let result = String(characters).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      return .closeTag(result)
    }),
    (newline, { _ in .newline }),
    (content, { .content($0) })
  ]

  init<Iterator: IteratorProtocol>(reading input: Iterator) where UnicodeScalar == Iterator.Element {
    lexer = Lexer(reading: input)
  }

  public mutating func next() -> Token? {
    guard readingBody else {
      guard let match = lexer.next(matching: header) else {
        self.readingBody = true
        return self.next()
      }
      let parts = String(match).components(separatedBy: CharacterSet(charactersIn: ":"))
      return .header(key: parts[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                     value: parts[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
    }
    for (matcher, tokenizer) in Tokenizer.bodyTokenizers {
      if let match = lexer.next(matching: matcher) {
        return tokenizer(String(match))
      }
    }
    return nil
  }
}

// MARK: - String Unicode Scalar Initializer

extension String {
  init<S: Sequence>(_ unicodeScalars: S) where UnicodeScalar == S.Iterator.Element {
    var view = String.UnicodeScalarView()
    view.append(contentsOf: unicodeScalars)
    self = String(view)
  }
}

// MARK: - Lexing Automata

private let header: NFA<UnicodeScalar> = {
  var nfa = NFA<UnicodeScalar>()
  let s1 = State(), s2 = State(), s3 = State(), final = State()
  nfa.mark(final, as: .terminating)
  nfa.transition(from: s3, to: final) { _ in true }
  nfa.transition(from: s2, to: s3) { $0 == UnicodeScalar("\r") }
  nfa.transition(from: s2, to: final) { $0 == UnicodeScalar("\n") }
  nfa.transition(from: s1, to: s2) { $0 == UnicodeScalar(":") }
  let fn: (UnicodeScalar) -> Bool = { !CharacterSet(charactersIn: "<>:\r\n").contains($0) }
  nfa.transition(from: s2, to: s2, over: fn)
  nfa.transition(from: s1, to: s1, over: fn)
  nfa.transition(from: nfa.root, to: s1, over: fn)
  return nfa
}()

private let openTag: NFA<UnicodeScalar> = {
  var nfa = NFA<UnicodeScalar>()
  let inner = State(), final = State()
  nfa.mark(final, as: .terminating)
  nfa.transition(from: nfa.root, to: inner) { $0 == UnicodeScalar("<") }
  nfa.transition(from: inner, to: inner) { !CharacterSet(charactersIn: "</>").contains($0) }
  nfa.transition(from: inner, to: final) { $0 == UnicodeScalar(">") }
  return nfa
}()

private let closeTag: NFA<UnicodeScalar> = {
  var nfa = NFA<UnicodeScalar>()
  let s1 = State(), s2 = State(), final = State()
  nfa.mark(final, as: .terminating)
  nfa.transition(from: nfa.root, to: s1) { $0 == UnicodeScalar("<") }
  nfa.transition(from: s1, to: s2) { $0 == UnicodeScalar("/") }
  nfa.transition(from: s2, to: s2) { !CharacterSet(charactersIn: "</>").contains($0) }
  nfa.transition(from: s2, to: final) { $0 == UnicodeScalar(">") }
  return nfa
}()

private let newline: NFA<UnicodeScalar> = {
    var nfa = NFA<UnicodeScalar>()
    let middle = State(), final = State()
    nfa.mark(final, as: .terminating)
    nfa.transition(from: nfa.root, to: middle) { $0 == UnicodeScalar("\r") }
    nfa.transition(from: nfa.root, to: final) { $0 == UnicodeScalar("\n") }
    nfa.transition(from: middle, to: final) { $0 == UnicodeScalar("\n") }
    return nfa
}()

private let content: NFA<UnicodeScalar> = {
    var nfa = NFA<UnicodeScalar>()
    let final = State()
    nfa.mark(final, as: .terminating)
    let fn: (UnicodeScalar) -> Bool = { !CharacterSet(charactersIn: "<>\r\n").contains($0) }
    nfa.transition(from: nfa.root, to: final, over: fn)
    nfa.transition(from: final, to: final, over: fn)
    return nfa
}()
