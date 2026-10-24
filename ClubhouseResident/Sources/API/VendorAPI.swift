import Foundation

enum VendorAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is invalid."
        case .invalidResponse:
            return "The server returned an unreadable response."
        case .server(let message):
            return message
        }
    }
}

final class VendorAPI {
    static let shared = VendorAPI()

    private let baseURL =
        "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/vendors"

    private init() {}

    func login(phone: String) async throws -> VendorAccount? {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw VendorAPIError.invalidURL
        }

        let body = try JSONSerialization.data(
            withJSONObject: ["phone": phone]
        )

        let (data, response) = try await perform(
            url: url,
            method: "POST",
            body: body
        )

        if response.statusCode == 404 {
            return nil
        }

        let decoded = try decode(
            VendorLoginResponse.self,
            from: data
        )

        guard (200...299).contains(response.statusCode) else {
            throw VendorAPIError.server(
                decoded.error ??
                "The vendor account could not be loaded."
            )
        }

        guard decoded.success == true else {
            throw VendorAPIError.server(
                decoded.error ??
                "The vendor account could not be loaded."
            )
        }

        return decoded.vendor
    }

    // Fetch every page, not just the default 50 new-first results.
    // The vendor inbox must retain viewed, accepted, and completed history.
    func fetchAllRequests(
        vendorId: Int
    ) async throws -> (requests: [VendorServiceRequest], newCount: Int) {
        var all: [VendorServiceRequest] = []
        var offset = 0
        var newCount = 0
        let pageSize = 100

        while true {
            try Task.checkCancellation()
            let page = try await fetchRequests(
                vendorId: vendorId,
                limit: pageSize,
                offset: offset
            )
            let items = page.requests ?? []
            all.append(contentsOf: items)
            newCount = page.new_count ?? newCount
            offset += items.count
            if items.isEmpty ||
                items.count < pageSize ||
                offset >= (page.total_count ?? Int.max) {
                break
            }
        }
        return (all, newCount)
    }

    func fetchRequests(
        vendorId: Int,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> VendorRequestsResponse {
        guard var components = URLComponents(
            string: "\(baseURL)/\(vendorId)/service-requests"
        ) else {
            throw VendorAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else {
            throw VendorAPIError.invalidURL
        }

        let (data, response) = try await perform(
            url: url,
            method: "GET"
        )

        let decoded = try decode(
            VendorRequestsResponse.self,
            from: data
        )

        guard
            (200...299).contains(response.statusCode),
            decoded.success == true
        else {
            throw VendorAPIError.server(
                decoded.error ??
                "The service requests could not be loaded."
            )
        }

        return decoded
    }

    func markViewed(
        vendorId: Int,
        requestId: String
    ) async throws -> VendorRequestMutationResponse {
        guard let url = URL(
            string:
                "\(baseURL)/\(vendorId)/service-requests/\(requestId)/viewed"
        ) else {
            throw VendorAPIError.invalidURL
        }

        let (data, response) = try await perform(
            url: url,
            method: "PATCH"
        )

        let decoded = try decode(
            VendorRequestMutationResponse.self,
            from: data
        )

        guard
            (200...299).contains(response.statusCode),
            decoded.success == true
        else {
            throw VendorAPIError.server(
                decoded.error ??
                "The request could not be marked viewed."
            )
        }

        return decoded
    }

    func updateStatus(
        vendorId: Int,
        requestId: String,
        status: String
    ) async throws -> VendorRequestMutationResponse {
        guard let url = URL(
            string:
                "\(baseURL)/\(vendorId)/service-requests/\(requestId)/status"
        ) else {
            throw VendorAPIError.invalidURL
        }

        let body = try JSONSerialization.data(
            withJSONObject: ["status": status]
        )

        let (data, response) = try await perform(
            url: url,
            method: "PATCH",
            body: body
        )

        let decoded = try decode(
            VendorRequestMutationResponse.self,
            from: data
        )

        guard
            (200...299).contains(response.statusCode),
            decoded.success == true
        else {
            throw VendorAPIError.server(
                decoded.error ??
                "The request status could not be updated."
            )
        }

        return decoded
    }

    func registerDevice(
        vendorId: Int,
        deviceToken: String,
        environment: String
    ) async throws {
        guard let url = URL(
            string: "\(baseURL)/\(vendorId)/devices"
        ) else {
            throw VendorAPIError.invalidURL
        }

        let body = try JSONSerialization.data(
            withJSONObject: [
                "device_token": deviceToken,
                "environment": environment,
                "bundle_id":
                    Bundle.main.bundleIdentifier ??
                    "com.clubhouselinks.app"
            ]
        )

        let (data, response) = try await perform(
            url: url,
            method: "POST",
            body: body
        )

        let decoded = try decode(
            VendorDeviceRegistrationResponse.self,
            from: data
        )

        guard
            (200...299).contains(response.statusCode),
            decoded.success == true
        else {
            throw VendorAPIError.server(
                decoded.error ??
                "This device could not be registered for notifications."
            )
        }
    }

    func submitResidentRequest(
        residentId: Int,
        payload: ResidentServiceRequestPayload
    ) async throws -> ResidentServiceRequestResponse {
        let urlString =
            "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/\(residentId)/service-requests"

        guard let url = URL(string: urlString) else {
            throw VendorAPIError.invalidURL
        }

        let body = try JSONEncoder().encode(payload)

        let (data, response) = try await perform(
            url: url,
            method: "POST",
            body: body
        )

        let decoded = try decode(
            ResidentServiceRequestResponse.self,
            from: data
        )

        guard
            (200...299).contains(response.statusCode),
            decoded.success == true
        else {
            throw VendorAPIError.server(
                decoded.error ??
                decoded.message ??
                "The service request could not be sent."
            )
        }

        return decoded
    }

    private func perform(
        url: URL,
        method: String,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "no-cache",
            forHTTPHeaderField: "Cache-Control"
        )

        request.setValue(
            "no-cache",
            forHTTPHeaderField: "Pragma"
        )
        request.httpMethod = method
        request.timeoutInterval = 30

        if let body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let (data, response) =
            try await URLSession.shared.data(for: request)

        guard let httpResponse =
            response as? HTTPURLResponse else {
            throw VendorAPIError.invalidResponse
        }

        return (data, httpResponse)
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let raw =
                String(data: data, encoding: .utf8) ??
                "Unreadable server response"

            print("Vendor API decode error:", error)
            print(raw)

            throw VendorAPIError.invalidResponse
        }
    }
}
