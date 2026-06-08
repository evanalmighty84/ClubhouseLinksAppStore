import SwiftUI

struct ResidentPortalView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            EventsView()
                .tabItem { Label("Events", systemImage: "calendar") }

            RequestView()
                .tabItem { Label("Request", systemImage: "paperplane.fill") }

            ContactView()
                .tabItem { Label("Contact", systemImage: "phone.fill") }
        }
        .tint(.cyan)
    }
}
