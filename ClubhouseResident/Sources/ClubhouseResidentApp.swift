import SwiftUI

@main
struct ClubhouseResidentApp: App {
    @UIApplicationDelegateAdaptor(
    ClubhouseAppDelegate.self
    )
    private var appDelegate

    @AppStorage("accountType")
    private var accountType = ""

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("residentId")
    private var residentId = 0

    var body: some Scene {
        WindowGroup {
            ResidentPortalView()
            .onAppear {
                syncPushRegistration()
            }
            .onChange(of: accountType) { _ in
                syncPushRegistration()
            }
            .onChange(of: vendorId) { _ in
                syncPushRegistration()
            }
            .onChange(of: residentId) { _ in
                syncPushRegistration()
            }
        }
    }

    private func syncPushRegistration() {
        let normalizedAccountType = accountType
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased()

        let isSignedInVendor =
        normalizedAccountType == "vendor" &&
        vendorId > 0

        let isSignedInResident =
        normalizedAccountType != "vendor" &&
        residentId > 0

        guard isSignedInVendor ||
        isSignedInResident else {
            return
        }

        VendorPushRegistration
        .activateForCurrentAccount()
    }
}