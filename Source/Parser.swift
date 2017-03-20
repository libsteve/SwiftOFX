//
//  Parser.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 3/19/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation

func parse(tokens: Tokenizer) -> Element? {
  var tokens = tokens
  var stack: [Element] = []

  while let t = tokens.next() {
    switch t {
    case .header(key: _, value: _): continue

    case let .openTag(name):
      stack.append(Element(name: name))

    case let .closeTag(name):
      var children: [Element] = []
      while var top = stack.last {
        let _ = stack.removeLast()
        guard top.name != name.uppercased() else {
          top.children += children.reversed()
          stack.append(top)
          break
        }
        children.append(top)
      }

    case .newline: continue

    case let .content(text):
      if var top = stack.last {
        stack.removeLast()
        top.content = (top.content == "") ? text : "\(top.content) \(text)"
        stack.append(top)
      }
    }
  }

  return stack.first
}
