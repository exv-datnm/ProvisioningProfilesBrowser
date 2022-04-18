import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

@main
struct ProvisioningProfileBrowserApp: App {
  @StateObject var profilesManager = ProvisioningProfilesManager()
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(profilesManager)
        .navigationTitle("Provisioning Profiles")
        .toolbar {
          Spacer()

          Button(action: { profilesManager.reload() }) {
            Label("Reload", systemImage: "arrow.clockwise")
          }
          .keyboardShortcut("r")
          .help("Reload")

          TextField("Search...", text: $profilesManager.query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 200)
            .help("Search list")
        }
    }
  }
}

