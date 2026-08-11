import SwiftUI

struct VendorResponse: Codable {
    let success: Bool?
    let vendors: [Vendor]?
    let error: String?
}

struct Vendor: Codable, Identifiable {
    let id: Int
    let neighborhood_id: Int?
    let company_name: String
    let category: String?
    let categories: [String]?
    let contact_name: String?
    let phone: String?
    let email: String?
    let website: String?
    let description: String?
    let logo_url: String?
    let active: Bool?
    let signup_count: Int?
    let signed_up_people: [VendorSignupPerson]?
}

struct VendorSignupPerson: Codable, Identifiable {
    let id: Int
    let first_name: String?
    let address: String?
    let distance_miles: Double?
    let finished_photo_url: String?
    let photo_approval_status: String?
}

struct VendorDirectoryView: View {

    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentNeighborhoodName") private var neighborhoodName = ""

    @State private var vendors: [Vendor] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 20) {

                    residentCard

                    Text("Vendor Directory")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)



                    if isLoading {
                        ProgressView()
                        .tint(.cyan)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    }

                    ForEach(vendors) { vendor in
                        VendorCard(vendor: vendor)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadVendors()
        }
    }

    private var residentCard: some View {
        VStack(spacing: 10) {
            Text("\(firstName) \(lastName)")
            .font(.title.bold())
            .foregroundStyle(.white)

            Text(neighborhoodName.isEmpty ? "Country Place" : neighborhoodName)
            .font(.headline)
            .foregroundStyle(.cyan)

            Text(phone)
            .foregroundStyle(.white.opacity(0.75))

            Text(address)
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .cyan.opacity(0.25), radius: 10)
    }

    private func loadVendors() {
        guard residentId > 0 else {
            errorMessage = "Resident profile not found."
            isLoading = false
            return
        }

        let urlString = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/vendors/\(residentId)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid vendor directory URL."
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No vendor data found."
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(VendorResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.success == true {
                        vendors = decoded.vendors ?? []
                    } else {
                        errorMessage = decoded.error ?? "Could not load vendors."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "Unreadable response"
                    errorMessage = rawResponse
                }
                print(error)
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()
    }
}