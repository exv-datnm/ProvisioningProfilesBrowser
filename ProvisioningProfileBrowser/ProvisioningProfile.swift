import AppKit
import SwiftyProvisioningProfile

@objcMembers
class ProvisioningProfile: NSObject {
  var url: URL
  var uuid: String
  var name: String
  var teamName: String
  var creationDate: Date
  var expirationDate: Date
  var appIdName: String
  var platforms: [String]
  var provisionedDevices: [String]?
  var teamIdentifiers: [String]
  var timeToLive: Int
  var version: Int

  var isMissingCertificate: Bool
  var isInvalidCertificate: Bool
  var isExpiredCertificate: Bool
  var isMissingPrivateKey: Bool
  
  init(profile: SwiftyProvisioningProfile.ProvisioningProfile, url: URL) {
    self.url = url

    self.uuid = profile.uuid
    self.name = profile.name
    self.teamName = profile.teamName
    self.creationDate = profile.creationDate
    self.expirationDate = profile.expirationDate
    self.appIdName = profile.appIdName
    self.platforms = profile.platforms
    self.provisionedDevices = profile.provisionedDevices
    self.teamIdentifiers = profile.teamIdentifiers
    self.timeToLive = profile.timeToLive
    self.version = profile.version

    self.isMissingCertificate = profile.isMissingCertificate
    self.isInvalidCertificate = profile.isInvalidCertificate
    self.isExpiredCertificate = profile.isExpiredCertificate
    self.isMissingPrivateKey = profile.isMissingPrivateKey
  }
}

extension ProvisioningProfile: Identifiable {
  public var id: String { uuid }
}

extension ProvisioningProfile {
  static func == (lhs: ProvisioningProfile, rhs: ProvisioningProfile) -> Bool {
    lhs.id == rhs.id
  }

  var color: NSColor {
    if issues != "" { return .systemRed }
    else if expirationDate < Date().addingTimeInterval(30 * 24 * 60 * 60) { return .systemOrange }
    return .labelColor
  }

  var issues: String {
    if expirationDate < Date() { return "Profile is expired" }
    if isMissingCertificate { return "Missing certificate" }
    if isInvalidCertificate { return "Certificate is invalidate" }
    if isExpiredCertificate { return "Certificate is expired" }
    if isMissingPrivateKey { return "Missing private key" }
    return ""
  }
}

extension ProvisioningProfile {
  var expirationDateString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: expirationDate)
  }
}
