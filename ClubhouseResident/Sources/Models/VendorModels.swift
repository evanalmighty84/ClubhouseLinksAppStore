import Foundation

struct VendorLoginResponse: Decodable {
    let success: Bool?
    let account_type: String?
    let vendor: VendorAccount?
    let error: String?
}

struct VendorAccount: Decodable {
    let id: Int
    let neighborhood_id: Int?
    let company_name: String
    let category: String?
    let contact_name: String?
    let phone: String?
    let email: String?
    let website: String?
    let description: String?
    let logo_url: String?
    let active: Bool?
}

struct VendorServiceRequest: Codable, Identifiable {
    let id: String
    let resident_id: Int?
    let vendor_id: Int?
    let service: String
    let sub_service: String?
    let message: String
    let status: String
    let created_at: String?
    let viewed_at: String?
    let accepted_at: String?
    let completed_at: String?

    let resident_first_name: String?
    let resident_last_name: String?
    let resident_phone: String?
    let resident_address: String?
    let resident_display_area_name: String?

    let vendor_company_name: String?
    let vendor_category: String?

    var residentDisplayName: String {
        let value = [
            resident_first_name,
            resident_last_name
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return value.isEmpty ? "Clubhouse Links Resident" : value
    }

    var serviceDisplayName: String {
        let cleanSubService = (sub_service ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanSubService.isEmpty
            ? service
            : "\(service) • \(cleanSubService)"
    }

    func replacingStatus(
        _ newStatus: String,
        viewedAt: String? = nil
    ) -> VendorServiceRequest {
        VendorServiceRequest(
            id: id,
            resident_id: resident_id,
            vendor_id: vendor_id,
            service: service,
            sub_service: sub_service,
            message: message,
            status: newStatus,
            created_at: created_at,
            viewed_at: viewedAt ?? viewed_at,
            accepted_at: accepted_at,
            completed_at: completed_at,
            resident_first_name: resident_first_name,
            resident_last_name: resident_last_name,
            resident_phone: resident_phone,
            resident_address: resident_address,
            resident_display_area_name: resident_display_area_name,
            vendor_company_name: vendor_company_name,
            vendor_category: vendor_category
        )
    }
}

struct VendorRequestsResponse: Decodable {
    let success: Bool?
    let requests: [VendorServiceRequest]?
    let total_count: Int?
    let new_count: Int?
    let limit: Int?
    let offset: Int?
    let error: String?
}

struct VendorRequestMutationResponse: Decodable {
    let success: Bool?
    let request: VendorServiceRequest?
    let message: String?
    let error: String?
}

struct VendorDeviceRegistrationResponse: Decodable {
    let success: Bool?
    let message: String?
    let error: String?
}

struct ResidentServiceRequestPayload: Encodable {
    let vendor_id: Int
    let service: String
    let sub_service: String?
    let message: String
}

struct ResidentServiceRequestResponse: Decodable {
    let success: Bool?
    let request_id: String?
    let notification_sent: Bool?
    let notification_sent_count: Int?
    let message: String?
    let error: String?
}
