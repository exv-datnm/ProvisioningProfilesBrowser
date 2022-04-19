//
//  SwiftyProvisioningProfile++.swift
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 18/04/2022.
//

import Foundation
import SwiftyProvisioningProfile

public extension DeveloperCertificate {
  var secCertificate: SecCertificate? {
    SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData)
  }

  var isMissingPrivateKey: Bool { secCertificate?.secIdentity == nil }
  var isMissing: Bool { certificate == nil || secCertificate == nil }
  var isInvalid: Bool {
    guard let cer = certificate else { return true }
    return cer.notValidBefore > Date()
  }
  var isExpired: Bool {
    guard let cer = certificate else { return true }
    return cer.notValidAfter < Date()
  }
}

extension SwiftyProvisioningProfile.ProvisioningProfile {
  var isMissingPrivateKey: Bool {
    guard developerCertificates.count > 0 else { return true }
    guard let result = developerCertificates.map({ $0.isMissingPrivateKey }).first(where: { $0 == false }) else { return true }
    return result
  }

  var isMissingCertificate: Bool {
    guard developerCertificates.count > 0 else { return true }
    guard let result = developerCertificates.map({ $0.isMissing }).first(where: { $0 == false }) else { return true }
    return result
  }

  var isInvalidCertificate: Bool {
    guard developerCertificates.count > 0 else { return true }
    guard let result = developerCertificates.map({ $0.isInvalid }).first(where: { $0 == false }) else { return true }
    return result
  }

  var isExpiredCertificate: Bool {
    guard developerCertificates.count > 0 else { return true }
    guard let result = developerCertificates.map({ $0.isExpired }).first(where: { $0 == false }) else { return true }
    return result
  }
}

public extension SecCertificate {
  /**
   * Loads a certificate from a DER encoded file. Wraps `SecCertificateCreateWithData`.
   *
   * - parameter file: The DER encoded file from which to load the certificate
   * - returns: A `SecCertificate` if it could be loaded, or `nil`
   */
  static func create(derEncodedFile file: String) -> SecCertificate? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return nil }
    let cfData = CFDataCreateWithBytesNoCopy(nil, (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), data.count, kCFAllocatorNull)
    return SecCertificateCreateWithData(kCFAllocatorDefault, cfData!)
  }

  /**
   * Returns the data of the certificate by calling `SecCertificateCopyData`.
   *
   * - returns: the data of the certificate
   */
  var data: Data {
    return SecCertificateCopyData(self) as Data
  }

  /**
   * Tries to return the public key of this certificate. Wraps `SecTrustCopyPublicKey`.
   * Uses `SecTrustCreateWithCertificates` with `SecPolicyCreateBasicX509()` policy.
   *
   * - returns: the public key if possible
   */
  var publicKey: SecKey? {
    let policy: SecPolicy = SecPolicyCreateBasicX509()
    var uTrust: SecTrust?
    let resultCode = SecTrustCreateWithCertificates([self] as CFArray, policy, &uTrust)
    guard resultCode == errSecSuccess, let trust = uTrust else { return nil }

    return SecTrustCopyKey(trust)
  }

  var serialNumberData: Data? {
    var error: Unmanaged<CFError>?
    let result = SecCertificateCopySerialNumberData(self, &error) as Data?
    if (error != nil) { print(error!) }
    return result
  }

  var secIdentity: SecIdentity? {
    guard let serialNumberData = self.serialNumberData else { return nil }

    let query: [NSString: Any] = [
      kSecClass: kSecClassCertificate,
      kSecAttrSerialNumber: serialNumberData,
      kSecReturnAttributes: kCFBooleanTrue as Any,
      kSecMatchLimit: kSecMatchLimitOne,
      kSecMatchPolicy: SecPolicyCreateBasicX509()
    ]

    var result: CFTypeRef?
    let errNo = SecItemCopyMatching(query as CFDictionary, &result)
    guard errNo == errSecSuccess else { return nil }
    return result as! SecIdentity?
  }
}

extension SecIdentity {
  /**
   * Retrieves the identity's private key. Wraps `SecIdentityCopyPrivateKey()`.
   *
   * - returns: the identity's private key, if possible
   */
  public var privateKey: SecKey? {
    var privKey : SecKey?
    guard SecIdentityCopyPrivateKey(self, &privKey) == errSecSuccess else {
      return nil
    }
    return privKey
  }
}

extension SecKey {

  /**
   * Provides the raw key data. Wraps `SecItemCopyMatching()`. Only works if the key is
   * available in the keychain. One common way of using this data is to derive a hash
   * of the key, which then can be used for other purposes.
   *
   * The format of this data is not documented. There's been some reverse-engineering:
   * https://devforums.apple.com/message/32089#32089
   * Apparently it is a DER-formatted sequence of a modulus followed by an exponent.
   * This can be converted to OpenSSL format by wrapping it in some additional DER goop.
   *
   * - returns: the key's raw data if it could be retrieved from the keychain, or `nil`
   */
  public var keyData: Data? {
    return try? getKeyData()
  }

  public func getKeyData() throws -> Data {
    var error: Unmanaged<CFError>?
    guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }
    return data
  }
}
