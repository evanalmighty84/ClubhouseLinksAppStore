import Foundation

struct ResidentHomeModeResponse:
Decodable {

    let success: Bool?
    let resident_id: Int?
    let neighborhood_id: Int?
    let neighborhood_name: String?
    let resident_home_mode: String?
    let error: String?
}


enum ResidentHomeModeAPIError:
LocalizedError {

    case invalidURL

    case invalidResponse

    case server(
    statusCode: Int,
    message: String
    )


    var errorDescription: String? {

        switch self {

        case .invalidURL:

            return
            "The resident home-mode URL is invalid."


        case .invalidResponse:

            return
            "The resident server returned an invalid response."


        case let .server(
        statusCode,
        message
        ):

            return
            "Resident home-mode request failed (\(statusCode)): \(message)"
        }
    }
}


final class ResidentHomeModeAPI {

    static let shared =
    ResidentHomeModeAPI()

    private init() {}


    private let baseURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com" +
    "/server/resident_function/api/residents"


    func getHomeMode(
    residentId: Int
    ) async throws
    -> ResidentHomeModeResponse {

        let urlString =
        baseURL +
        "/profile/\(residentId)/home-mode"

        guard let url =
        URL(string: urlString)
        else {
            throw
            ResidentHomeModeAPIError.invalidURL
        }

        var request =
        URLRequest(url: url)

        request.httpMethod = "GET"

        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        let (
        data,
        response
        ) = try await
        URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse
        else {
            throw
            ResidentHomeModeAPIError
            .invalidResponse
        }

        let decoded =
        try? JSONDecoder()
        .decode(
            ResidentHomeModeResponse.self,
            from: data
        )

        guard
        (200...299)
        .contains(
            httpResponse.statusCode
        ),
        decoded?.success == true
        else {

            let body =
            String(
                data: data,
                encoding: .utf8
            ) ?? ""

            throw
            ResidentHomeModeAPIError
            .server(
                statusCode:
                httpResponse.statusCode,

                message:
                decoded?.error ??
                body
            )
        }

        guard let decoded else {
            throw
            ResidentHomeModeAPIError
            .invalidResponse
        }

        return decoded
    }
}