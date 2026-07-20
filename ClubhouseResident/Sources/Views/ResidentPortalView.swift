import SwiftUI

struct ResidentPortalView: View {
    @AppStorage("residentSelectedTab") private var selectedTab = "home"

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag("home")

            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            .tag("events")

            NavigationStack {
                RequestView()
            }
            .tabItem {
                Label("Submit Job", systemImage: "paperplane.fill")
            }
            .tag("submit")

            NavigationStack {
                ContactView()
            }
            .tabItem {
                Label("Request Service", systemImage: "phone.fill")
            }
            .tag("contact")
        }
        .tint(.cyan)
    }
}