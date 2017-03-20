import Foundation

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
