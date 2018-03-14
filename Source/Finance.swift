import Foundation

/// A contract for any type which represents some parsable OFX data.
protocol Information {
  /// The OFX tag that denotes this type of information.
  static var label: String { get }

  /// A method of constructing an instance of this information structure from within an OFX element.
  /// - parameter element: An OFX element containing sub-elements, of which only one represents
  ///                      the data necessary to create an instance of this information structure.
  init?(parent element: Element)
}

/// A type alias to semantically specify some identity.
public typealias Identifier = String

/// Information about the entity which provided the OFX file.
public struct Institute: Information {
  static let label: String = "FI"

  /// The name of the institution.
  public var name: String

  /// An identifier for this specific institution.
  public var id: Identifier

  init?(parent element: Element) {
    guard let element = element[Institute.label] else { return nil }
    name = element["ORG"]?.content ?? ""
    id = element["FID"]?.content ?? ""
  }
}

/// Information about the method through which the OFX file was obtained.
public struct Session: Information {
  static let label: String = "SONRS"

//  var status: String // STATUS

  /// The date when the OFX file was obtained.
  public var date: Date

//  var language: Strng // LANGUAGE

  /// The institute that provided the OFX file.
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

/// The login information used to obtain the OFX file.
public struct Account: Information {
  static let label: String = "ACCTINFO"

  /// A description of the account.
  public var description: String

  /// An account's login identifier associated with the logged in user's username.
  public var identifier: Identifier

  /// The identifier of the bank or institution to which this account belongs.
  public var bank: Identifier?

  /// The type of this account login.
  public var type: String?

  init?(parent element: Element) {
    guard let element = element[Account.label] else { return nil }
    self.init(element: element)
  }

  /// Create an `Account` data structure using information within the given OFX element.
  /// - parameter element: An OFX element that contains all necessary data needed to build an
  ///                      an `Account` structure.
  init?(element: Element) {
    guard let identifier = element["ACCTID"]?.content else { return nil }
    self.identifier = identifier
    description = element["DESC"]?.content ?? ""
    bank = element["BANKID"]?.content
    type = element["ACCTTYPE"]?.content
  }
}

extension Array where Element == Account {
  /// Create an array of sequential `Account` data structures within the given OFX element.
  /// - parameter element: An OFX element containing multiple sub-elements, many of which contain
  ///                      the data necessary to create an `Account ` structure.
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["ACCTINFOTRNRS"] else { return nil }
    self = element.children.filter { $0.name == Account.label }.reduce([]) { collection, element in
      guard let account = Account(element: element) else { return collection }
      return collection + [account]
    }
  }
}

/// A specific exchange of finances from accounts, such as a purchase, loan payment, deposit, etc.
public struct Transaction: Information {
  static let label: String = "STMTTRN"

  /// The method used to facilitate this transaction.
  public var type: String

  /// The date this transaction occured.
  public var date: Date

  /// The amount of money exchanged through this transaction.
  public var amount: Double

  /// A unique identifier for this transaction.
  public var identifier: Identifier

  /// A description for the transaction.
  public var description: String

  /// The recipient of the money from this transaction.
  public var payee: String?

  /// A description for the transaction.
  public var memo: String?

  /// An official categorization for this transaction.
  public var category: MerchantCategoryCode?

  /// The identifying number for the check through which this transaction was facilitated.
  public var check: Int?

  init?(parent element: Element) {
    guard let element = element[Transaction.label] else { return nil }
    self.init(element: element)
  }

  /// Create a `Transaction` data structure using information within the given OFX element.
  /// - parameter element: An OFX element that contains all necessary data needed to build an
  ///                      a `Transaction` structure.
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

/// A collection of transactions between specified dates.
public struct Statement: Information {
  static let label: String = "BANKTRANLIST"

  /// The earliest date a transaction on this statement could have occured.
  public var start: Date

  /// The lastest date a transaction on this statement could have occured.
  public var end: Date

  /// A collection of all transactions for this statement's period.
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

/// Information pertaining to a Bank Account.
public struct BankAccount: Information {
  static let label: String = "STMTTRNRS"

  /// The kind of currency used with this account.
  public var currency: String

  /// An identifier indicating which bank this account belongs to.
  public var bank: Identifier

  /// An identifier for this account, such as the specific account number.
  public var account: Identifier

  /// The type of this bank account. (i.e. Checking, Credit, etc.)
  public var type: String

  /// The amount of money remaining within the account.
  public var balance: Double

  /// The date that this information was last updated.
  public var date: Date

  /// The account statement and transactions.
  public var statement: Statement

  init?(parent element: Element) {
    guard let element = element[BankAccount.label] else { return nil }
    self.init(element: element)
  }

  /// Create a `BankAccount` data structure using information within the given OFX element.
  /// - parameter element: An OFX element that contains all necessary data needed to build an
  ///                      a `BankAccount` structure.
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
  /// Create an array of sequential `BankAccount` data structures within the given OFX element.
  /// - parameter element: An OFX element containing multiple sub-elements, many of which contain
  ///                      the data necessary to create a `BankAccount ` structure.
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["BANKMSGSRSV1"] else { return nil }
    self =
      element.children.filter { $0.name == BankAccount.label }.reduce([]) { collection, element in
        guard let account = BankAccount(element: element) else { return collection }
        return collection + [account]
      }
  }
}

/// Information pertaining to a Credit Card Account.
public struct CreditAccount: Information {
  static let label: String = "CCSTMTTRNRS"

  /// The kind of currency used with this account.
  public var currency: String

  /// An identifier for this account.
  public var account: Identifier

  /// The amount of money remaining within the account.
  public var balance: Double

  /// The date that this information was last updated.
  public var date: Date

//  var remainingCredit: Double
//  var remainingCreditDate: Date

  /// The account statement and transactions.
  public var statement: Statement

  init?(parent element: Element) {
    guard let element = element[CreditAccount.label] else { return nil }
    self.init(element: element)
  }

  /// Create a `CreditAccount` data structure using information within the given OFX element.
  /// - parameter element: An OFX element that contains all necessary data needed to build an
  ///                      a `CreditAccount` structure.
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
  /// Create an array of sequential `CreditAccount` data structures within the given OFX element.
  /// - parameter element: An OFX element containing multiple sub-elements, many of which contain
  ///                      the data necessary to create a `CreditAccount ` structure.
  init?(parent element: SwiftOFX.Element) {
    guard let element = element["CREDITCARDMSGSRSV1"] else { return nil }
    self =
      element.children.filter { $0.name == CreditAccount.label }.reduce([]) { collection, element in
        guard let account = CreditAccount(element: element) else { return collection }
        return collection + [account]
      }
  }
}

/// A collection of all relevant information held within an OFX file.
public struct Finance: Information {
  static let label: String = "OFX"

  /// Information about the session from which the OFX file came.
  public var session: Session

  /// Information about the login accounts relevant to the OFX file.
  public var accounts: [Account]

  /// Information about bank accounts from the OFX file.
  public var bankAccounts: [BankAccount]

  /// Information about credit card accounts from the OFX file.
  public var creditAccounts: [CreditAccount]

  init?(parent element: Element) {
    guard let element = element[Finance.label] else { return nil }
    self.init(element: element)
  }

  /// Create an array of sequential `Finance` data structures within the given OFX element.
  /// - parameter element: An OFX element containing multiple sub-elements, many of which contain
  ///                      the data necessary to create a `Finance ` structure.
  init?(element: Element) {
    guard let session = element["SIGNONMSGSRSV1", "SONRS"].flatMap({ Session(parent: $0) })
      else { return nil }
    self.session = session
    self.accounts = Array<Account>(parent: element) ?? []
    self.bankAccounts = Array<BankAccount>.init(parent: element) ?? []
    self.creditAccounts = Array<CreditAccount>.init(parent: element) ?? []
  }

  /// Gather the financial information from the data of an OFX file.
  /// - parameter data: A data object containing OFX formatted information.
  public init?(data: Data) {
    var iterator = data.makeIterator()
    
    let tokens = Tokenizer(reading: AnyIterator { iterator.next().map(UnicodeScalar.init(_:)) })
    guard let element = parse(tokens: tokens) else { return nil }
    self.init(element: element)
  }

  /// Gather the financial information from the OFX file at the given path.
  /// - parameter path: The file path to an OFX file.
  public init?(file path: String) {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    self.init(data: data)
  }
}
