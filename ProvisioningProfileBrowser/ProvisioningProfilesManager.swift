import Foundation
import SwiftyProvisioningProfile
import Witness
import AppKit

class ProvisioningProfilesManager: ObservableObject {
  @Published var profiles = [ProvisioningProfile]() {
    didSet {
      updateVisibleProfiles(query: query)
    }
  }
  @Published var visibleProfiles: [ProvisioningProfile] = []
  @Published var loading = false
  @Published var query = "" {
    didSet {
      updateVisibleProfiles(query: query)
    }
  }
  @Published var error: Error?

  private var witness: Witness?

  init() {
    self.witness = Witness(
      paths: [Self.provisioningProfilesDirectory.path],
      flags: .FileEvents,
      latency: 0.3
    ) { [unowned self] events in
      self.reload()
    }
  }

  private static var provisioningProfilesDirectory: URL {
    let libraryDirectoryURL = try! FileManager.default.url(
      for: .libraryDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
    return libraryDirectoryURL.appendingPathComponent("MobileDevice").appendingPathComponent("Provisioning Profiles")
  }

  func reload() {
    loading = true

    do {
      let enumerator = FileManager.default.enumerator(
        at: Self.provisioningProfilesDirectory,
        includingPropertiesForKeys: [.nameKey],
        options: .skipsHiddenFiles,
        errorHandler: nil
      )!

      var profiles = [ProvisioningProfile]()
      for case let url as URL in enumerator {
        let profileData = try Data(contentsOf: url)
        let profile = try SwiftyProvisioningProfile.ProvisioningProfile.parse(from: profileData)
        profiles.append(
          ProvisioningProfile(
            url: url,
            uuid: profile.uuid,
            name: profile.name,
            teamName: profile.teamName,
            creationDate: profile.creationDate,
            expirationDate: profile.expirationDate
          )
        )
      }

      self.loading = false
      self.profiles = profiles
    } catch {
      self.loading = false
      self.error = error
    }
  }

  func delete(profile: ProvisioningProfile) {
    let alertView = NSAlert()
    alertView.messageText = "Do you want to delete Provisioning Profile?"
    alertView.informativeText = "\(profile.name)\n\(profile.uuid)"
    alertView.addButton(withTitle: "Cancel")
    alertView.addButton(withTitle: "Yes")
    alertView.alertStyle = .warning
    guard alertView.runModal() == .alertSecondButtonReturn else { return }

    do {
      try FileManager.default.trashItem(at: profile.url, resultingItemURL: nil)
      profiles.removeAll { $0 == profile }
    } catch {
      print(error.localizedDescription)
    }
  }

  private func updateVisibleProfiles(query: String) {
    if query.isEmpty {
      visibleProfiles = profiles
    } else {
      visibleProfiles = profiles.filter {
        $0.name.localizedCaseInsensitiveContains(query) ||
        $0.teamName.localizedCaseInsensitiveContains(query) ||
        $0.uuid.localizedCaseInsensitiveContains(query)
      }
    }
  }

  func revealInFinder(profile: ProvisioningProfile) {
    NSWorkspace.shared.activateFileViewerSelecting([profile.url])
  }
}

