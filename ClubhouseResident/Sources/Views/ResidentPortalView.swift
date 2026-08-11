import SwiftUI

struct ResidentPortalView: View {
    @AppStorage("residentSelectedTab") private var selectedTab = "home"
    @AppStorage("accountType") private var accountType = ""

    private var isVendorAccount: Bool {
        accountType
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased() == "vendor"
    }

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
                Label(
                    isVendorAccount ? "Jobs Submitted" : "Submit Job",
                    systemImage: "paperplane.fill"
                )
            }
            .tag("submit")

            NavigationStack {
                ContactView()
            }
            .tabItem {
                Label(
                    isVendorAccount ? "Service Requests" : "Request Service",
                    systemImage: "phone.fill"
                )
            }
            .tag("contact")
        }
        .tint(.cyan)
    }
}