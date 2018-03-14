import Foundation

/// A data structure which represents the content of a tagged unit of data from an OFX file.
struct Element {
  /// The tag name used to signify the type of data represented within this element.
  var name: String

  /// Any raw string data not associated with any sub-elements.
  var content: String = ""

  /// A list of all sub-elements contained within this OFX element.
  var children: [Element] = []

  /// Create an `Element` instance with the given OFX tag name.
  init(name: String) {
    self.name = name.uppercased()
  }
}

extension Element {
  /// A convenience method for accessing data nested within a hierarchy of `Element` structures.
  /// - parameter tags: An ordered list of tags denoting the path of sub-elements to follow in order
  ///                   to find a specific element.
  ///  - returns: The first `Element` instance nested within the given tag path.
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
