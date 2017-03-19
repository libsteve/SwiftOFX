//
//  Token.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 3/18/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation

enum Token {
  case header(key: String, value: String)
  case openTag(String)
  case closeTag(String)
  case newline
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
