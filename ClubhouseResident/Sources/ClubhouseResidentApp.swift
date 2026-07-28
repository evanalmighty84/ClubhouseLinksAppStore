import SwiftUI

@main
struct ClubhouseResidentApp: App {
    @UIApplicationDelegateAdaptor(ClubhouseAppDelegate.self)
    private var appDelegate
    var body: some Scene {
        WindowGroup {
            ResidentPortalView()
        }
    }
}
