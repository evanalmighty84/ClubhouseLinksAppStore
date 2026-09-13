import Foundation

struct SupportResident: Codable, Identifiable {
    let id: Int
    let first_name: String?
    let last_name: String?
    let phone: String?
    let address: String?
    let neighborhood_id: Int?
    let neighborhood_name: String?

    var displayName: String {
        let parts = [
            first_name ?? "",
            last_name ?? ""
        ]
        .filter { !$0.isEmpty }

        return parts.isEmpty
        ? "Resident #\(id)"
        : parts.joined(separator: " ")
    }
}

private struct SupportResidentSearchPayload: Encodable {
    let device_token: String
    let search: String
}

private struct SupportResidentSearchResponse: Decodable {
    let success: Bool?
    let residents: [SupportResident]?
    let error: String?
}

private struct SupportResidentSwitchPayload: Encodable {
    let device_token: String
    let resident_id: Int
    let environment: String
}

private struct SupportResidentSwitchResponse: Decodable {
    let success: Bool?
    let resident: SupportResident?
    let message: String?
    let error: String?
}

private struct SupportResidentClearPayload: Encodable {
    let device_token: String
}

private struct SupportResidentClearResponse: Decodable {
    let success: Bool?
    let message: String?
    let error: String?
}

enum SupportResidentAPIError: LocalizedError {
    case noDeviceToken
    case invalidURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .noDeviceToken:
            return "This device does not have an APNs token yet."

        case .invalidURL:
            return "The support URL is invalid."

        case .invalidResponse:
            return "The support server returned an invalid response."

        case .server(let message):
            return message
        }
    }
}

final class SupportResidentAPI {

    static let shared = SupportResidentAPI()

    private let baseURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com" +
    "/server/resident_function/api/vendors"

    private init() {}

    var storedDeviceToken: String? {
        let defaults = UserDefaults.standard

        let token =
        defaults.string(
            forKey: "clubhouseAPNsDeviceToken"
        )
        ?? defaults.string(
            forKey: "vendorAPNsDeviceToken"
        )

        guard let token,
        !token.isEmpty else {
            return nil
        }

        return token
    }

    // MARK: - Support Authorization

    /*
     * Calling search with an empty string is intentional.
     *
     * The backend verifies the support device BEFORE checking
     * the search length, so this doubles as our device
     * authorization check without needing another endpoint.
     */
    func isAuthorizedSupportDevice(
    vendorId: Int
    ) async -> Bool {

        do {
            _ = try await searchResidents(
                vendorId: vendorId,
                search: ""
            )

            return true
        } catch {
            return false
        }
    }

    // MARK: - Search

    func searchResidents(
    vendorId: Int,
    search: String
    ) async throws -> [SupportResident] {

        guard let token = storedDeviceToken else {
            throw SupportResidentAPIError.noDeviceToken
        }

        let urlString =
        "\(baseURL)/\(vendorId)" +
        "/support-residents/search"

        guard let url = URL(string: urlString) else {
            throw SupportResidentAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
        try JSONEncoder().encode(
            SupportResidentSearchPayload(
                device_token: token,
                search: search
            )
        )

        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse else {
            throw SupportResidentAPIError.invalidResponse
        }

        let decoded =
        try JSONDecoder().decode(
            SupportResidentSearchResponse.self,
            from: data
        )

        guard (200...299).contains(
            httpResponse.statusCode
        ),
        decoded.success != false else {

            throw SupportResidentAPIError.server(
                decoded.error ??
                "Unable to search residents."
            )
        }

        return decoded.residents ?? []
    }

    // MARK: - Switch

    func switchResident(
    vendorId: Int,
    residentId: Int
    ) async throws -> SupportResident {

        guard let token = storedDeviceToken else {
            throw SupportResidentAPIError.noDeviceToken
        }

        let urlString =
        "\(baseURL)/\(vendorId)" +
        "/support-resident"

        guard let url = URL(string: urlString) else {
            throw SupportResidentAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
        try JSONEncoder().encode(
            SupportResidentSwitchPayload(
                device_token: token,
                resident_id: residentId,
                environment:
                VendorPushRegistration.environment
            )
        )

        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse else {
            throw SupportResidentAPIError.invalidResponse
        }

        let decoded =
        try JSONDecoder().decode(
            SupportResidentSwitchResponse.self,
            from: data
        )

        guard (200...299).contains(
            httpResponse.statusCode
        ),
        decoded.success == true,
        let resident = decoded.resident else {

            throw SupportResidentAPIError.server(
                decoded.error ??
                "Unable to switch resident."
            )
        }

        return resident
    }

    // MARK: - Clear

    func clearResident(
    vendorId: Int
    ) async throws {

        guard let token = storedDeviceToken else {
            throw SupportResidentAPIError.noDeviceToken
        }

        let urlString =
        "\(baseURL)/\(vendorId)" +
        "/support-resident"

        guard let url = URL(string: urlString) else {
            throw SupportResidentAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
        try JSONEncoder().encode(
            SupportResidentClearPayload(
                device_token: token
            )
        )

        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse else {
            throw SupportResidentAPIError.invalidResponse
        }

        let decoded =
        try JSONDecoder().decode(
            SupportResidentClearResponse.self,
            from: data
        )

        guard (200...299).contains(
            httpResponse.statusCode
        ),
        decoded.success != false else {

            throw SupportResidentAPIError.server(
                decoded.error ??
                "Unable to end support mode."
            )
        }
    }
}