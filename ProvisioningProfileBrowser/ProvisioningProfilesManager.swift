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
      paths: [Self.provisioningProfilesDirectoryURL.path],
      flags: .FileEvents,
      latency: 0.3
    ) { [unowned self] events in
      self.reload()
    }
  }

  private static var provisioningProfilesDirectoryURL: URL {
    let libraryDirectoryURL = try! FileManager.default.url(
      for: .libraryDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
    return libraryDirectoryURL.appendingPathComponent("MobileDevice").appendingPathComponent("Provisioning Profiles")
  }

  private static var desktopUrl: URL {
    URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop")
  }

  func reload() {
    loading = true

    do {
      let enumerator = FileManager.default.enumerator(
        at: Self.provisioningProfilesDirectoryURL,
        includingPropertiesForKeys: [.nameKey],
        options: .skipsHiddenFiles,
        errorHandler: nil
      )!

      var profiles = [ProvisioningProfile]()
      for case let url as URL in enumerator {
        let profileData = try Data(contentsOf: url)
        let profile = try SwiftyProvisioningProfile.ProvisioningProfile.parse(from: profileData)
        profiles.append(ProvisioningProfile(profile: profile, url: url))
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
    guard FileManager.default.fileExists(atPath: profile.url.path) else {
      let alertView = NSAlert()
      alertView.messageText = "File not found!"
      alertView.informativeText = "\(profile.name)\n\(profile.uuid)"
      alertView.addButton(withTitle: "OK")
      alertView.alertStyle = .warning
      alertView.runModal()
      return
    }
    NSWorkspace.shared.activateFileViewerSelecting([profile.url])
  }

  func exportProfile(_ profile: ProvisioningProfile) {
    let savePanel = NSSavePanel()
    savePanel.canCreateDirectories = true
    savePanel.nameFieldStringValue = profile.name
    savePanel.allowedContentTypes = [.init(filenameExtension: "mobileprovision")!]
    savePanel.prompt = "Export"
    savePanel.title = "Export Provisioning File (replace if exits)"
    savePanel.directoryURL = Self.desktopUrl
    savePanel.begin { (result) in
      guard result == .OK, let url = savePanel.url else { return }
      try? FileManager.default.copyItem(at: profile.url, to: url)
    }
  }
}

