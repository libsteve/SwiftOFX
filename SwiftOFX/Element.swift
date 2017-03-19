//
//  Element.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 2/27/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation

struct Element {
  var name: String
  var content: String = ""
  var children: [Element] = []

  init(name: String) {
    self.name = name.uppercased()
  }
}

extension Element {
  subscript(tags: String...) -> Element? {
    get {
      return tags.reduce(self as Element?) { element, tag in
        let tag = tag.uppercased()
        return element?.children.first { element in element.name == tag }
      }
    }
  }
}

extension Element: CustomStringConvertible {
  var description: String {
    return "<\(name)>\n\(content)\(children.map { $0.description }.joined(separator: "\n"))\n</\(name)>"
  }
}
