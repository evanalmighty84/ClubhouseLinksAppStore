import SwiftUI
import UIKit


// MARK: - API Models

struct StreetFairVendorDirectoryResponse: Decodable {

    let success: Bool?
    let neighborhood: StreetFairNeighborhood?
    let vendors: [StreetFairVendor]?
    let error: String?
}


struct StreetFairNeighborhood: Decodable {

    let id: Int
    let name: String
    let resident_home_mode: String?
}


struct StreetFairVendor: Decodable, Identifiable {

    let id: Int
    let company_name: String
    let category: String?
    let categories: [String]?
    let contact_name: String?
    let phone: String?
    let email: String?
    let website: String?
    let description: String?
    let logo_url: String?
    let sort_order: Int?
}


// MARK: - Street Fair Vendor Directory

struct StreetFairVendorDirectoryView: View {

    let residentId: Int

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var neighborhoodName = ""

    @State
    private var vendors: [StreetFairVendor] = []

    @State
    private var isLoading = false

    @State
    private var errorMessage = ""


    private let apiBaseURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com" +
    "/server/resident_function/api/residents"


    var body: some View {

        NeonBackground {

            ScrollView {

                VStack(spacing: 20) {

                    header

                    if isLoading {

                        loadingView

                    } else if !errorMessage.isEmpty {

                        errorView

                    } else if vendors.isEmpty {

                        emptyView

                    } else {

                        vendorList
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .task(id: residentId) {

            await loadStreetFairVendors()
        }
    }


    // MARK: - Header

    private var header: some View {

        VStack(spacing: 18) {

            HStack {

                Button {

                    dismiss()

                } label: {

                    Image(
                        systemName: "chevron.left"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(.cyan)
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        .white.opacity(0.08)
                    )
                    .clipShape(
                        Circle()
                    )
                }

                Spacer()
            }


            Image(
                systemName: "person.3.fill"
            )
            .font(
                .system(size: 46)
            )
            .foregroundStyle(.orange)


            Text(
                "Street Fair Contractors"
            )
            .font(.largeTitle.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(
                .center
            )


            if !neighborhoodName.isEmpty {

                Text(neighborhoodName)
                .font(.title3.bold())
                .foregroundStyle(.cyan)
            }


            Text(
                "These local professionals are participating in your neighborhood's Clubhouse Links Street Fair."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.70)
            )
            .multilineTextAlignment(
                .center
            )
        }
    }


    // MARK: - Vendor List

    private var vendorList: some View {

        LazyVStack(spacing: 16) {

            ForEach(vendors) { vendor in

                vendorCard(vendor)
            }
        }
    }


    // MARK: - Vendor Card

    private func vendorCard(
    _ vendor: StreetFairVendor
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack(
                alignment: .top,
                spacing: 14
            ) {

                vendorLogo(vendor)

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        vendor.company_name
                    )
                    .font(.title3.bold())
                    .foregroundStyle(.white)


                    if let category =
                    vendor.category,
                    !category.isEmpty {

                        Text(
                            displayCategory(
                                category
                            )
                        )
                        .font(.subheadline.bold())
                        .foregroundStyle(.cyan)
                    }


                    if let contact =
                    vendor.contact_name,
                    !contact.isEmpty {

                        Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(0.72)
                        )
                    }
                }

                Spacer()
            }


            if let categories =
            vendor.categories,
            !categories.isEmpty {

                serviceList(categories)
            }


            if let description =
            vendor.description,
            !description.isEmpty {

                Text(description)
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.72)
                )
                .lineSpacing(3)
            }


            contactButtons(vendor)
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            LinearGradient(
                colors: [
                    .white.opacity(0.08),
                    .purple.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .cyan.opacity(0.30),
                lineWidth: 1
            )
        }
    }


    // MARK: - Logo

    @ViewBuilder
    private func vendorLogo(
    _ vendor: StreetFairVendor
    ) -> some View {

        if let logoString =
        vendor.logo_url,
        !logoString.isEmpty,
        let url =
        URL(string: logoString) {

            AsyncImage(url: url) { phase in

                switch phase {

                case .empty:

                    ProgressView()
                    .tint(.cyan)

                case .success(let image):

                    image
                    .resizable()
                    .scaledToFit()

                case .failure:

                    vendorLogoPlaceholder

                @unknown default:

                    vendorLogoPlaceholder
                }
            }
            .frame(
                width: 72,
                height: 72
            )
            .padding(6)
            .background(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )

        } else {

            vendorLogoPlaceholder
        }
    }


    private var vendorLogoPlaceholder: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        .cyan.opacity(0.25),
                        .purple.opacity(0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            Image(
                systemName: "building.2.fill"
            )
            .font(.title2)
            .foregroundStyle(.white)
        }
        .frame(
            width: 72,
            height: 72
        )
    }


    // MARK: - Services

    private func serviceList(
    _ categories: [String]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("SERVICES")
            .font(.caption.bold())
            .tracking(1)
            .foregroundStyle(
                .white.opacity(0.55)
            )


            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 8) {

                    ForEach(
                        categories,
                        id: \.self
                    ) { category in

                        Text(
                            displayCategory(
                                category
                            )
                        )
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(
                            .horizontal,
                            11
                        )
                        .padding(
                            .vertical,
                            7
                        )
                        .background(
                            .cyan.opacity(0.16)
                        )
                        .clipShape(
                            Capsule()
                        )
                        .overlay {

                            Capsule()
                            .stroke(
                                .cyan.opacity(0.35),
                                lineWidth: 1
                            )
                        }
                    }
                }
            }
        }
    }


    // MARK: - Contact Buttons

    @ViewBuilder
    private func contactButtons(
    _ vendor: StreetFairVendor
    ) -> some View {

        let phone =
        vendor.phone?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        let email =
        vendor.email?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""


        if !phone.isEmpty ||
        !email.isEmpty {

            HStack(spacing: 10) {

                if !phone.isEmpty {

                    Button {

                        callVendor(phone)

                    } label: {

                        Label(
                            "Call",
                            systemImage:
                            "phone.fill"
                        )
                        .font(.headline.bold())
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            12
                        )
                        .foregroundStyle(.white)
                        .background(
                            .green.opacity(0.75)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }


                if !email.isEmpty {

                    Button {

                        emailVendor(email)

                    } label: {

                        Label(
                            "Email",
                            systemImage:
                            "envelope.fill"
                        )
                        .font(.headline.bold())
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            12
                        )
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [
                                    .cyan,
                                    .purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }


    // MARK: - Loading

    private var loadingView: some View {

        VStack(spacing: 14) {

            ProgressView()
            .tint(.cyan)
            .scaleEffect(1.2)

            Text(
                "Loading Street Fair contractors..."
            )
            .font(.headline)
            .foregroundStyle(.white)
        }
        .padding(.vertical, 50)
    }


    // MARK: - Error

    private var errorView: some View {

        VStack(spacing: 16) {

            Image(
                systemName:
                "exclamationmark.triangle.fill"
            )
            .font(.largeTitle)
            .foregroundStyle(.orange)


            Text(errorMessage)
            .font(.subheadline)
            .foregroundStyle(.white)
            .multilineTextAlignment(
                .center
            )


            Button {

                Task {

                    await loadStreetFairVendors()
                }

            } label: {

                Text("Try Again")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    24
                )
                .padding(
                    .vertical,
                    12
                )
                .background(
                    .purple.opacity(0.8)
                )
                .clipShape(
                    Capsule()
                )
            }
        }
        .padding(.vertical, 40)
    }


    // MARK: - Empty

    private var emptyView: some View {

        VStack(spacing: 14) {

            Image(
                systemName:
                "person.3.sequence.fill"
            )
            .font(.largeTitle)
            .foregroundStyle(.cyan)


            Text(
                "Street Fair Contractors Coming Soon"
            )
            .font(.title3.bold())
            .foregroundStyle(.white)


            Text(
                "Participating professionals will appear here as they join your neighborhood's Street Fair."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.68)
            )
            .multilineTextAlignment(
                .center
            )
        }
        .padding(28)
        .frame(
            maxWidth: .infinity
        )
        .background(
            .white.opacity(0.06)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }


    // MARK: - API

    @MainActor
    private func loadStreetFairVendors()
    async {

        guard residentId > 0 else {

            errorMessage =
            "No resident account was found."

            return
        }


        isLoading = true
        errorMessage = ""

        defer {

            isLoading = false
        }


        let urlString =
        apiBaseURL +
        "/\(residentId)/street-fair/vendors"


        guard let url =
        URL(string: urlString)
        else {

            errorMessage =
            "Invalid Street Fair vendor URL."

            return
        }


        do {

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
            response
            as? HTTPURLResponse
            else {

                errorMessage =
                "Invalid server response."

                return
            }


            let decoded =
            try JSONDecoder()
            .decode(
                StreetFairVendorDirectoryResponse.self,
                from: data
            )


            guard
            (200...299)
            .contains(
                httpResponse.statusCode
            ),
            decoded.success == true
            else {

                errorMessage =
                decoded.error ??
                "Unable to load Street Fair contractors."

                return
            }


            neighborhoodName =
            decoded.neighborhood?.name
            ?? ""

            vendors =
            decoded.vendors
            ?? []


            print(
                "[Street Fair Vendors]",
                neighborhoodName,
                vendors.count
            )

        } catch {

            print(
                "[Street Fair Vendors] Error:",
                error
            )

            errorMessage =
            error.localizedDescription
        }
    }


    // MARK: - Helpers

    private func displayCategory(
    _ value: String
    ) -> String {

        value
        .replacingOccurrences(
            of: "_",
            with: " "
        )
        .split(separator: " ")
        .map {
            String($0).capitalized
        }
        .joined(separator: " ")
    }


    private func callVendor(
    _ phone: String
    ) {

        let digits =
        phone.filter {
            $0.isNumber
        }

        guard
        !digits.isEmpty,
        let url =
        URL(
            string:
            "tel://\(digits)"
        )
        else {
            return
        }

        UIApplication.shared.open(url)
    }


    private func emailVendor(
    _ email: String
    ) {

        guard
        let url =
        URL(
            string:
            "mailto:\(email)"
        )
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}