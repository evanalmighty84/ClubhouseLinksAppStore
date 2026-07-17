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
                Label("Request", systemImage: "paperplane.fill")
            }

            NavigationStack {
                ContactView()
            }
            .tabItem {
                Label("Submit Job", systemImage: "phone.fill")
            }
        }
        .tint(.cyan)
    }
}