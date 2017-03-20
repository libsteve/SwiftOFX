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

public typealias Identifier = String

public struct Institute: Information {
  static let label: String = "FI"

  public var name: String
  public var id: Identifier

  init?(parent element: Element) {
    guard let element = element[Institute.label] else { return nil }
    name = element["ORG"]?.content ?? ""
    id = element["FID"]?.content ?? ""
  }
}

public struct Session: Information {
  static let label: String = "SONRS"

//  var status: String // STATUS
  public var date: Date
//  var language: Strng // LANGUAGE
  public var institute: Institute

  init?(parent element: Element) {
    guard
      let institute = Institute(parent: element),
      let dateString = element["DTSERVER"]?.content,
      let date = Date(string: dateString) else { return nil }
    self.institute = institute
    self.date = date
  }
}

public struct Account: Information {
  static let label: String = "ACCTINFO"

  public var description: String
  public var identifier: Identifier
  public var bank: Identifier?
  public var type: String?

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

public struct Transaction: Information {
  static let label: String = "STMTTRN"

  public var type: String
  public var date: Date
  public var amount: Double
  public var identifier: Identifier
  public var description: String
  public var payee: String?
  public var memo: String?
  public var category: MerchantCategoryCode?
  public var check: Int?

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

public struct Statement: Information {
  static let label: String = "BANKTRANLIST"

  public var start: Date
  public var end: Date
  public var transactions: [Transaction]

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

public struct BankAccount: Information {
  static let label: String = "STMTTRNRS"

  public var currency: String
  public var bank: Identifier
  public var account: Identifier
  public var type: String
  public var balance: Double
  public var date: Date
  public var statement: Statement

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

public struct CreditAccount: Information {
  static let label: String = "CCSTMTTRNRS"

  public var currency: String
  public var account: Identifier
  public var balance: Double
  public var date: Date
//  var remainingCredit: Double
//  var remainingCreditDate: Date
  public var statement: Statement

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

public struct Finance: Information {
  static let label: String = "OFX"

  public var session: Session
  public var accounts: [Account]
  public var bankAccounts: [BankAccount]
  public var creditAccounts: [CreditAccount]

  init?(parent element: Element) {
    guard let element = element[Finance.label] else { return nil }
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
