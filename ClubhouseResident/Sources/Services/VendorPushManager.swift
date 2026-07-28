import SwiftUI
import UIKit
import UserNotifications

extension Notification.Name {
    static let vendorServiceRequestNotificationTapped =
        Notification.Name(
            "vendorServiceRequestNotificationTapped"
        )

    static let vendorServiceRequestReceived =
        Notification.Name(
            "vendorServiceRequestReceived"
        )
}

enum VendorPushRegistration {
    static var environment: String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }

    static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, error in
                    if let error {
                        print(
                            "Notification authorization error:",
                            error
                        )
                    }

                    guard granted else {
                        return
                    }

                    DispatchQueue.main.async {
                        UIApplication.shared
                            .registerForRemoteNotifications()
                    }
                }

            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared
                        .registerForRemoteNotifications()
                }

            case .denied:
                print(
                    "Notification permission is disabled for this app."
                )

            @unknown default:
                break
            }
        }
    }

    static func syncStoredToken() {
        let defaults = UserDefaults.standard
        let vendorId = defaults.integer(forKey: "vendorId")

        guard vendorId > 0 else {
            return
        }

        guard let token = defaults.string(
            forKey: "vendorAPNsDeviceToken"
        ),
        !token.isEmpty else {
            requestAuthorization()
            return
        }

        Task {
            do {
                try await VendorAPI.shared.registerDevice(
                    vendorId: vendorId,
                    deviceToken: token,
                    environment: environment
                )
            } catch {
                print(
                    "Stored vendor token sync failed:",
                    error.localizedDescription
                )
            }
        }
    }
}

final class ClubhouseAppDelegate:
NSObject,
UIApplicationDelegate,
UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        let defaults = UserDefaults.standard

        if defaults.string(forKey: "accountType") == "vendor",
           defaults.integer(forKey: "vendorId") > 0 {
            VendorPushRegistration.requestAuthorization()
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken
            deviceToken: Data
    ) {
        let token = deviceToken
            .map { String(format: "%02x", $0) }
            .joined()

        let defaults = UserDefaults.standard
        defaults.set(
            token,
            forKey: "vendorAPNsDeviceToken"
        )

        let vendorId = defaults.integer(forKey: "vendorId")

        guard vendorId > 0 else {
            return
        }

        Task {
            do {
                try await VendorAPI.shared.registerDevice(
                    vendorId: vendorId,
                    deviceToken: token,
                    environment:
                        VendorPushRegistration.environment
                )

                print(
                    "Vendor APNs device registered:",
                    vendorId
                )
            } catch {
                print(
                    "Vendor APNs device registration failed:",
                    error.localizedDescription
                )
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError
            error: Error
    ) {
        print(
            "APNs registration failed:",
            error.localizedDescription
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(
            name: .vendorServiceRequestReceived,
            object: nil
        )

        return [.banner, .list, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo =
            response.notification.request.content.userInfo

        if let requestId =
            userInfo["request_id"] as? String {
            UserDefaults.standard.set(
                requestId,
                forKey: "vendorOpenRequestId"
            )
        } else if let requestId =
                    userInfo["request_id"] as? Int {
            UserDefaults.standard.set(
                String(requestId),
                forKey: "vendorOpenRequestId"
            )
        }

        UserDefaults.standard.set(
            "contact",
            forKey: "residentSelectedTab"
        )

        NotificationCenter.default.post(
            name: .vendorServiceRequestNotificationTapped,
            object: nil
        )
    }
}
