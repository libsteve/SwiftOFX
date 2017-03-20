//
//  Lexer.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 3/12/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation
import Reggie

struct Tokenizer: IteratorProtocol {
  private var lexer: Lexer<UnicodeScalar>
  private var readingBody: Bool = false

  private static let bodyTokenizers: [(Automata<NFA<UnicodeScalar>>, (String) -> Token)] = [
    (openTag, {
      let characters = $0.characters.dropFirst().dropLast()
      let result = String(characters).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      return .openTag(result)
    }),
    (closeTag, {
      let characters = $0.characters.dropFirst().dropFirst().dropLast()
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

/// MARK: - String Unicode Scalar Initializer

extension String {
  init<S: Sequence>(_ unicodeScalars: S) where UnicodeScalar == S.Iterator.Element {
    var view = String.UnicodeScalarView()
    view.append(contentsOf: unicodeScalars)
    self = String(view)
  }
}

// MARK: - Lexing Automata

private let header: Automata<NFA<UnicodeScalar>> = {
  let final = NFA<UnicodeScalar>(terminal: true)
  var s3 = NFA<UnicodeScalar>(transition: Transition(to: final) { $0 == UnicodeScalar("\n") })
  var s2 = NFA<UnicodeScalar>(transitions: Transition(to: s3) { $0 == UnicodeScalar("\r") },
                                           Transition(to: final) { $0 == UnicodeScalar("\n") })
  var s1 = NFA<UnicodeScalar>(transition: Transition(to: s2) { $0 == UnicodeScalar(":") })
  var root = NFA<UnicodeScalar>()
  let fn: (UnicodeScalar) -> Bool  = { !CharacterSet(charactersIn: "<>:\r\n").contains($0) }
  s2.transition(to: s2, over: fn)
  s1.transition(to: s1, over: fn)
  root.transition(to: s1, over: fn)
  return Automata(root: root)
}()

private let openTag: Automata<NFA<UnicodeScalar>> = {
  let final = NFA<UnicodeScalar>(terminal: true)
  var inner = NFA<UnicodeScalar>(transition: Transition(to: final) { $0 == UnicodeScalar(">") })
  let root = NFA<UnicodeScalar>(transition: Transition(to: inner) { $0 == UnicodeScalar("<") })
  inner.transition(to: inner) { !CharacterSet(charactersIn: "</>").contains($0) }
  return Automata(root: root)
}()

private let closeTag: Automata<NFA<UnicodeScalar>> = {
  let final = NFA<UnicodeScalar>(terminal: true)
  var s2 = NFA<UnicodeScalar>(transition: Transition(to: final) { $0 == UnicodeScalar(">") })
  let s1 = NFA<UnicodeScalar>(transition: Transition(to: s2) { $0 == UnicodeScalar("/") })
  let root = NFA<UnicodeScalar>(transition: Transition(to: s1) { $0 == UnicodeScalar("<") })
  s2.transition(to: s2) { !CharacterSet(charactersIn: "</>").contains($0) }
  return Automata(root: root)
}()

private let newline: Automata<NFA<UnicodeScalar>> = {
  let final = NFA<UnicodeScalar>(terminal: true)
  let middle = NFA<UnicodeScalar>(transitions: Transition(to: final) { $0 == UnicodeScalar("\n") })
  let root = NFA<UnicodeScalar>(transitions: Transition(to: final) { $0 == UnicodeScalar("\n") },
                                             Transition(to: middle) { $0 == UnicodeScalar("\r") })
  return Automata(root: root)
}()

private let content: Automata<NFA<UnicodeScalar>> = {
  var final = NFA<UnicodeScalar>(terminal: true)
  var root = NFA<UnicodeScalar>()
  let t = Transition(to: final) { !CharacterSet(charactersIn: "<>\r\n").contains($0) }
  final.add(transition: t)
  root.add(transition: t)
  return Automata(root: root)
}()
