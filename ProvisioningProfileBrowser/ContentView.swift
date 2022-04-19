import SwiftUI

struct ContentView: View {
  @EnvironmentObject var profilesManager: ProvisioningProfilesManager
  @State private var selectedProfileID: ProvisioningProfile.ID?

  var body: some View {
    VSplitView {
      ProfilesList(data: $profilesManager.visibleProfiles, selection: $selectedProfileID)

      if let selectedProfileID = selectedProfileID,
         let selectedProfile = profilesManager.visibleProfiles.first(where: { $0.id == selectedProfileID }) {
        QuickLookPreview(url: selectedProfile.url)

      } else {
        Color(.windowBackgroundColor)
          .frame(width: nil, height: 0, alignment: .center)
      }
    }
    .onAppear(perform: profilesManager.reload)
    .frame(minWidth: 300, minHeight: 300)
    .alert(isPresented: $profilesManager.error.isNotNil) {
      Alert(
        title: Text("Error"),
        message: Text(profilesManager.error!.localizedDescription),
        dismissButton: Alert.Button.default(Text("OK"))
      )
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

