import Foundation

/// The possible date formats that an OFX file can contain.
private let formats = [
  "YYYYMMDDhhmmss.XXX[ZZ:zzz]",
  "YYYYMMDDhhmmss.XXX",
  "YYYYMMDDhhmmss[ZZ:zzz]",
  "YYYYMMDDhhmmss",
  "YYYYMMDDHHmmss.XXX[ZZ:zzz]",
  "YYYYMMDDHHmmss.XXX",
  "YYYYMMDDHHmmss[ZZ:zzz]",
  "YYYYMMDDHHmmss",
  "YYYYMMDD[ZZ:zzz]",
  "YYYYMMDD"
]

extension Date {
  /// Create a data instance from some OFX-originated string data that should represent a date.
  internal init?(string: String) {
    guard string != "" else { return nil }
    let formatter = DateFormatter()
    let maybeDate = formats.reduce(nil as Date?) { result, format in
      guard result == nil else { return result }
      formatter.dateFormat = format
      return formatter.date(from: string)
    }
    guard let date = maybeDate else { return nil }
    self = date
  }

}
