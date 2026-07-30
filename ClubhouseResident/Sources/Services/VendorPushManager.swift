import Foundation
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

    static let residentServiceRequestStatusChanged =
    Notification.Name(
        "residentServiceRequestStatusChanged"
    )

    static let residentServiceRequestNotificationTapped =
    Notification.Name(
        "residentServiceRequestNotificationTapped"
    )
}

private struct ResidentDeviceRegistrationPayload: Encodable {
    let device_token: String
    let environment: String
    let bundle_id: String
}

private struct ResidentDeviceRegistrationResponse: Decodable {
    let success: Bool?
    let message: String?
    let error: String?
}

private enum PushRegistrationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The notification registration URL is invalid."

        case .invalidResponse:
            return "The notification server returned an invalid response."

        case let .server(statusCode, message):
            return "Notification registration failed (\(statusCode)): \(message)"
        }
    }
}

enum VendorPushRegistration {
    private static let storedTokenKey =
    "clubhouseAPNsDeviceToken"

    private static let legacyVendorTokenKey =
    "vendorAPNsDeviceToken"

    private static let bundleId =
    "com.clubhouselinks.app"

    private static let apiBaseURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com" +
    "/server/resident_function/api"

    static var environment: String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }

    /// Call this after either a resident or vendor successfully signs in.
    /// Save accountType/residentId/vendorId first, then call this method.
    static func activateForCurrentAccount() {
        requestAuthorization()
        syncStoredToken()
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
                            "[APNs] Notification authorization error:",
                            error.localizedDescription
                        )
                    }

                    guard granted else {
                        print(
                            "[APNs] Notification permission was not granted."
                        )
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
                    "[APNs] Notification permission is disabled for this app."
                )

            @unknown default:
                break
            }
        }
    }

    static func didReceiveDeviceToken(
    _ deviceToken: Data
    ) {
        let token = deviceToken
        .map {
            String(
                format: "%02x",
                $0
            )
        }
        .joined()

        guard !token.isEmpty else {
            print(
                "[APNs] Apple returned an empty device token."
            )
            return
        }

        let defaults = UserDefaults.standard

        defaults.set(
            token,
            forKey: storedTokenKey
        )

        // Keep this legacy key populated so any older vendor code
        // that still reads it continues to work.
        defaults.set(
            token,
            forKey: legacyVendorTokenKey
        )

        print(
            "[APNs] Device token received:",
            String(token.prefix(12)) + "..."
        )

        registerTokenForCurrentAccount(token)
    }

    static func syncStoredToken() {
        let defaults = UserDefaults.standard

        let token =
        defaults.string(forKey: storedTokenKey) ??
        defaults.string(forKey: legacyVendorTokenKey)

        guard let token,
        !token.isEmpty else {
            print(
                "[APNs] No stored device token is available yet."
            )
            return
        }

        registerTokenForCurrentAccount(token)
    }

    private static func registerTokenForCurrentAccount(
    _ token: String
    ) {
        let defaults = UserDefaults.standard

        let accountType = defaults
        .string(forKey: "accountType")?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased() ?? ""

        let vendorId = defaults.integer(
            forKey: "vendorId"
        )

        let residentId = defaults.integer(
            forKey: "residentId"
        )

        if accountType == "vendor",
        vendorId > 0 {
            registerVendorDevice(
                vendorId: vendorId,
                token: token
            )
            return
        }

        if residentId > 0 {
            registerResidentDevice(
                residentId: residentId,
                token: token
            )
            return
        }

        print(
            "[APNs] The token is stored, but no signed-in account was found."
        )
    }

    private static func registerVendorDevice(
    vendorId: Int,
    token: String
    ) {
        Task {
            do {
                try await VendorAPI.shared.registerDevice(
                    vendorId: vendorId,
                    deviceToken: token,
                    environment: environment
                )

                print(
                    "[APNs] Vendor device registered:",
                    vendorId,
                    String(token.prefix(12)) + "..."
                )
            } catch {
                print(
                    "[APNs] Vendor device registration failed:",
                    error.localizedDescription
                )
            }
        }
    }

    private static func registerResidentDevice(
    residentId: Int,
    token: String
    ) {
        Task {
            do {
                try await sendResidentDeviceRegistration(
                    residentId: residentId,
                    token: token
                )

                print(
                    "[APNs] Resident device registered:",
                    residentId,
                    String(token.prefix(12)) + "..."
                )
            } catch {
                print(
                    "[APNs] Resident device registration failed:",
                    error.localizedDescription
                )
            }
        }
    }

    private static func sendResidentDeviceRegistration(
    residentId: Int,
    token: String
    ) async throws {
        let urlString =
        apiBaseURL +
        "/residents/\(residentId)/devices"

        guard let url = URL(string: urlString) else {
            throw PushRegistrationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let payload = ResidentDeviceRegistrationPayload(
            device_token: token,
            environment: environment,
            bundle_id: bundleId
        )

        request.httpBody =
        try JSONEncoder().encode(payload)

        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse else {
            throw PushRegistrationError.invalidResponse
        }

        let decoded =
        try? JSONDecoder().decode(
            ResidentDeviceRegistrationResponse.self,
            from: data
        )

        guard (200...299).contains(
            httpResponse.statusCode
        ),
        decoded?.success != false else {
            let responseBody =
            String(
                data: data,
                encoding: .utf8
            ) ?? ""

            throw PushRegistrationError.server(
                statusCode:
                httpResponse.statusCode,
                message:
                decoded?.error ??
                responseBody
            )
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

        let accountType = defaults
        .string(forKey: "accountType")?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased() ?? ""

        let vendorId = defaults.integer(
            forKey: "vendorId"
        )

        let residentId = defaults.integer(
            forKey: "residentId"
        )

        let hasSignedInVendor =
        accountType == "vendor" &&
        vendorId > 0

        let hasSignedInResident =
        residentId > 0

        if hasSignedInVendor ||
        hasSignedInResident {
            VendorPushRegistration
            .activateForCurrentAccount()
        }

        return true
    }

    func applicationDidBecomeActive(
    _ application: UIApplication
    ) {
        VendorPushRegistration
        .syncStoredToken()
    }

    func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken
    deviceToken: Data
    ) {
        VendorPushRegistration
        .didReceiveDeviceToken(deviceToken)
    }

    func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError
    error: Error
    ) {
        print(
            "[APNs] Registration failed:",
            error.localizedDescription
        )
    }

    func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo =
        notification.request.content.userInfo

        if isResidentServiceRequestNotification(
            userInfo
        ) {
            NotificationCenter.default.post(
                name:
                .residentServiceRequestStatusChanged,
                object: nil,
                userInfo: userInfo
            )
        } else {
            NotificationCenter.default.post(
                name:
                .vendorServiceRequestReceived,
                object: nil,
                userInfo: userInfo
            )
        }

        return [
            .banner,
            .list,
            .sound,
            .badge
        ]
    }

    func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
    ) async {
        let userInfo =
        response.notification.request.content.userInfo

        if isResidentServiceRequestNotification(
            userInfo
        ) {
            handleResidentNotificationTap(
                userInfo
            )
        } else {
            handleVendorNotificationTap(
                userInfo
            )
        }
    }

    private func handleResidentNotificationTap(
    _ userInfo: [AnyHashable: Any]
    ) {
        let defaults = UserDefaults.standard

        if let requestId =
        requestIdString(from: userInfo) {
            defaults.set(
                requestId,
                forKey: "residentOpenRequestId"
            )
        }

        // "contact" is the existing stored value used by the
        // Request Service tab in this app.
        defaults.set(
            "contact",
            forKey: "residentSelectedTab"
        )

        NotificationCenter.default.post(
            name:
            .residentServiceRequestNotificationTapped,
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleVendorNotificationTap(
    _ userInfo: [AnyHashable: Any]
    ) {
        let defaults = UserDefaults.standard

        if let requestId =
        requestIdString(from: userInfo) {
            defaults.set(
                requestId,
                forKey: "vendorOpenRequestId"
            )
        }

        defaults.set(
            "contact",
            forKey: "residentSelectedTab"
        )

        NotificationCenter.default.post(
            name:
            .vendorServiceRequestNotificationTapped,
            object: nil,
            userInfo: userInfo
        )
    }

    private func isResidentServiceRequestNotification(
    _ userInfo: [AnyHashable: Any]
    ) -> Bool {
        let notificationType =
        stringValue(
            userInfo["notification_type"]
        )
        .lowercased()

        return notificationType ==
        "resident_service_request_status" ||
        notificationType ==
        "resident_service_request_received" ||
        notificationType.hasPrefix(
            "resident_service_request"
        )
    }

    private func requestIdString(
    from userInfo: [AnyHashable: Any]
    ) -> String? {
        stringValue(
            userInfo["request_id"]
        )
    }

    private func stringValue(
    _ value: Any?
    ) -> String {
        if let string = value as? String {
            return string
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        return ""
    }
}
