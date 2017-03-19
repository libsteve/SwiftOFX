//
//  Reader.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 2/27/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation

protocol Information {
  static var label: String { get }
  init?(parent element: Element)
}

typealias Identifier = String

struct Institute: Information {
  static let label: String = "FI"

  var name: String
  var id: Identifier

  init?(parent element: Element) {
    guard let element = element[Institute.label] else { return nil }
    name = element["ORG"]?.content ?? ""
    id = element["FID"]?.content ?? ""
  }
}

struct Session: Information {
  static let label: String = "SONRS"

//  var status: String // STATUS
  var date: Date
//  var language: Strng // LANGUAGE
  var institute: Institute

  init?(parent element: Element) {
    guard
      let institute = Institute(parent: element),
      let dateString = element["DTSERVER"]?.content,
      let date = Date(string: dateString) else { return nil }
    self.institute = institute
    self.date = date
  }
}

struct Account: Information {
  static let label: String = "ACCTINFO"

  var description: String
  var identifier: Identifier
  var bank: Identifier?
  var type: String?

  init?(parent element: Element) {
    guard let element = element[Account.label] else { return nil }
    self.init(element: element)
  }

  init?(element: Element) {
    guard let identifier = element["ACCTID"]?.content else { return nil }
    self.identifier = identifier
    description = element["DESC"]?.content ?? ""
    bank = element["BANKID"]?.content
    type = element["ACCTTYPE"]?.content
  }
}

extension Array where Element == Account {
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["ACCTINFOTRNRS"] else { return nil }
    self = element.children.filter { $0.name == Account.label }.reduce([]) { collection, element in
      guard let account = Account(element: element) else { return collection }
      return collection + [account]
    }
  }
}

struct Transaction: Information {
  static let label: String = "STMTTRN"

  var type: String
  var date: Date
  var amount: Double
  var identifier: Identifier
  var description: String
  var payee: String?
  var memo: String?
  var category: MerchantCategoryCode?
  var check: Int?

  init?(parent element: Element) {
    guard let element = element[Transaction.label] else { return nil }
    self.init(element: element)
  }

  init?(element: Element) {
    guard
      let type = element["TRNTYPE"]?.content,
      let date = (element["DTPOSTED"]?.content).flatMap(Date.init(string:)),
      let amount = (element["TRNAMT"]?.content).flatMap(Double.init(_:)),
      let identifier = element["FITID"]?.content,
      let description = element["NAME"]?.content else { return nil }
    self.type = type
    self.date = date
    self.amount = amount
    self.identifier = identifier
    self.description = description
    payee = element["PAYEE"]?.content
    memo = element["MEMO"]?.content
    category = (element["SIC"]?.content).flatMap(MerchantCategoryCode.init(string:))
    check = Int(element["CHECKNUM"]?.content ?? "")
  }
}

struct Statement: Information {
  static let label: String = "BANKTRANLIST"

  var start: Date
  var end: Date
  var transactions: [Transaction]

  init?(parent element: Element) {
    guard
      let element = element[Statement.label],
      let start = (element["DTSTART"]?.content).flatMap(Date.init(string:)),
      let end = (element["DTEND"]?.content).flatMap(Date.init(string:)) else { return nil }
    self.start = start
    self.end = end
    transactions =
      element.children.filter { $0.name == Transaction.label }.reduce([]) { collection, element in
        guard let transaction = Transaction(element: element) else { return collection }
        return collection + [transaction]
      }
  }
}

struct BankAccount: Information {
  static let label: String = "STMTTRNRS"

  var currency: String
  var bank: Identifier
  var account: Identifier
  var type: String
  var balance: Double
  var date: Date
  var statement: Statement

  init?(parent element: Element) {
    guard let element = element[BankAccount.label] else { return nil }
    self.init(element: element)
  }

  init?(element: Element) {
    guard
      let currency = element["STMTRS", "CURDEF"]?.content,
      let bank = element["STMTRS", "BANKACCTFROM", "BANKID"]?.content,
      let account = element["STMTRS", "BANKACCTFROM", "ACCTID"]?.content,
      let type = element["STMTRS", "BANKACCTFROM", "ACCTTYPE"]?.content,
      let balance = (element["STMTRS", "LEDGERBAL", "BALAMT"]?.content).flatMap(Double.init(_:)),
      let date = (element["STMTRS", "LEDGERBAL", "DTASOF"]?.content).flatMap(Date.init(string:)),
      let statement = element["STMTRS"].flatMap(Statement.init(parent:)) else { return nil }
    self.currency = currency
    self.bank = bank
    self.account = account
    self.type = type
    self.balance = balance
    self.date = date
    self.statement = statement
  }
}

extension Array where Element == BankAccount {
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["BANKMSGSRSV1"] else { return nil }
    self =
      element.children.filter { $0.name == BankAccount.label }.reduce([]) { collection, element in
        guard let account = BankAccount(element: element) else { return collection }
        return collection + [account]
      }
  }
}

struct CreditAccount: Information {
  static let label: String = "CCSTMTTRNRS"

  var currency: String
  var account: Identifier
  var balance: Double
  var date: Date
//  var remainingCredit: Double
//  var remainingCreditDate: Date
  var statement: Statement

  init?(parent element: Element) {
    guard let element = element[CreditAccount.label] else { return nil }
    self.init(element: element)
  }

  init?(element: Element) {
    guard
      let currency = element["CCSTMTRS", "CURDEF"]?.content,
      let account = element["CCSTMTRS", "CCACCTFROM", "ACCTID"]?.content,
      let balance = (element["CCSTMTRS", "LEDGERBAL", "BALAMT"]?.content).flatMap(Double.init(_:)),
      let date = (element["CCSTMTRS", "LEDGERBAL", "DTASOF"]?.content).flatMap(Date.init(string:)),
      let statement = element["CCSTMTRS"].flatMap(Statement.init(parent:)) else { return nil }
    self.currency = currency
    self.account = account
    self.balance = balance
    self.date = date
    self.statement = statement
  }
}

extension Array where Element == CreditAccount {
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["CREDITCARDMSGSRSV1"] else { return nil }
    self =
      element.children.filter { $0.name == CreditAccount.label }.reduce([]) { collection, element in
        guard let account = CreditAccount(element: element) else { return collection }
        return collection + [account]
      }
  }
}

struct FinancialInformation: Information {
  static let label: String = "OFX"

  var session: Session
  var accounts: [Account]
  var bankAccounts: [BankAccount]
  var creditAccounts: [CreditAccount]

  init?(parent element: Element) {
    guard let element = element[FinancialInformation.label] else { return nil }
    self.init(element: element)
  }

  init?(element: Element) {
    guard let session = element["SIGNONMSGSRSV1", "SONRS"].flatMap({ Session(parent: $0) })
      else { return nil }
    self.session = session
    self.accounts = Array<Account>(parent: element) ?? []
    self.bankAccounts = Array<BankAccount>.init(parent: element) ?? []
    self.creditAccounts = Array<CreditAccount>.init(parent: element) ?? []
  }

  public init?(data: Data) {
    var iterator = data.makeIterator()
    
    let tokens = Tokenizer(reading: AnyIterator { iterator.next().map(UnicodeScalar.init(_:)) })
    guard let element = parse(tokens: tokens) else { return nil }
    self.init(element: element)
  }

  public init?(file path: String) {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    self.init(data: data)
  }
}
