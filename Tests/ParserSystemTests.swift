import XCTest
@testable import SwiftOFX

class ParserSystemTests: XCTestCase {

  var data: Data!

  override func setUp() {
    super.setUp()
    let path = Bundle(for: type(of: self)).path(forResource: "example", ofType: "ofx")!
    data = FileManager.default.contents(atPath: path)!
  }

  func testFinance() {
    let information = Finance(data: data)
    XCTAssertNotNil(information, "The OFX data should be properly parsed.")

    guard let info = information else { return }
    XCTAssertEqual(info.accounts.count, 0, "Expecting example.ofx to have no ACCOUNT entries.")
    XCTAssertEqual(info.bankAccounts.count, 1, "Expecting example.ofx to have one BANK ACCOUNT entry.")
    XCTAssertEqual(info.bankAccounts[0].statement.transactions.count, 2)
    XCTAssertEqual(info.creditAccounts.count, 1, "Expecting example.ofx to have one CREDIT ACCOUNT entry.")
    XCTAssertEqual(info.creditAccounts[0].statement.transactions.count, 1)
  }
  
}
