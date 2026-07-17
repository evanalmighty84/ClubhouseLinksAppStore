import SwiftUI

struct ResidentPortalView: View {
    var body: some View {
        TabView {

            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }

            NavigationStack {
                RequestView()
            }
            .tabItem {
                Label("Submit Job", systemImage: "paperplane.fill")
            }

            NavigationStack {
                ContactView()
            }
            .tabItem {
                Label("Request Service", systemImage: "phone.fill")
            }
        }
        .tint(.cyan)
    }
}