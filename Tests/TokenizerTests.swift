import XCTest
@testable import SwiftOFX

class TokenizerTests: XCTestCase {

  func testHeader() {
    var tokenizer = Tokenizer(reading: "KEY:VALUE\n".unicodeScalars.makeIterator())
    let token = tokenizer.next()
    XCTAssertNotNil(token)
    XCTAssertEqual(token, .header(key: "KEY", value: "VALUE"))
    XCTAssertNil(tokenizer.next())

    tokenizer = Tokenizer(reading: "KEY:VALUE\r\n".unicodeScalars.makeIterator())
    let other = tokenizer.next()
    XCTAssertNotNil(other)
    XCTAssertEqual(other, .header(key: "KEY", value: "VALUE"))
    XCTAssertNil(tokenizer.next())
  }

  func testOpenTag() {
    var tokenizer = Tokenizer(reading: "<TAG>\n".unicodeScalars.makeIterator())
    let token = tokenizer.next()
    XCTAssertNotNil(token)
    XCTAssertEqual(token, .openTag("TAG"))
    XCTAssertNotNil(tokenizer.next())
  }

  func testCloseTag() {
    var tokenizer = Tokenizer(reading: "</TAG>\n".unicodeScalars.makeIterator())
    let token = tokenizer.next()
    XCTAssertNotNil(token)
    XCTAssertEqual(token, .closeTag("TAG"))
    XCTAssertNotNil(tokenizer.next())
  }

  func testNewline() {
    var tokenizer = Tokenizer(reading: "\r\n".unicodeScalars.makeIterator())
    let token = tokenizer.next()
    XCTAssertNotNil(token)
    XCTAssertEqual(token, .newline)
    XCTAssertNil(tokenizer.next())

    tokenizer = Tokenizer(reading: "\n".unicodeScalars.makeIterator())
    let other = tokenizer.next()
    XCTAssertNotNil(other)
    XCTAssertEqual(other, .newline)
    XCTAssertNil(tokenizer.next())
  }

  func testContent() {
    var tokenizer = Tokenizer(reading: "THIS IS TEXT\r\n".unicodeScalars.makeIterator())
    let token = tokenizer.next()
    XCTAssertNotNil(token)
    XCTAssertEqual(token, .content("THIS IS TEXT"))

    let next = tokenizer.next()
    XCTAssertNotNil(next)
    XCTAssertEqual(next, .newline)

    XCTAssertNil(tokenizer.next())
  }

}
