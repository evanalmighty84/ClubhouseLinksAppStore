import SwiftUI

private struct ResidentServiceRequestsResponse: Decodable {
    let success: Bool?
    let requests: [ResidentServiceRequestStatusItem]?
    let total_count: Int?
    let error: String?
}

private struct ResidentServiceRequestStatusItem:
Decodable,
Identifiable {

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
    let vendor_company_name: String?
    let vendor_category: String?
    let vendor_logo_url: String?
}

struct ContactView: View {
    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage("accountType")
    private var accountType = ""

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentFirstName")
    private var firstName = ""

    @AppStorage("residentLastName")
    private var lastName = ""

    @AppStorage("residentPhone")
    private var phone = ""

    @AppStorage("residentSelectedTab")
    private var selectedTab = "home"

    @State private var selectedService = "Painting"
    @State private var selectedVendorId = 0
    @State private var message = ""

    @State private var vendorOptions: [Vendor] = []
    @State private var vendorOptionsLoading = false
    @State private var vendorOptionsError = ""
    @State private var submitMessage = ""
    @State private var isSubmitting = false

    @State private var residentRequests:
    [ResidentServiceRequestStatusItem] = []

    @State private var residentRequestsLoading = false
    @State private var residentRequestsError = ""

    private let fallbackServiceOptions = [
        "Painting",
        "Pool Service",
        "Roofing",
        "Realtor",
        "Plumbing",
        "Electrical",
        "Landscaping",
        "General Contractor"
    ]

    private var isVendorAccount: Bool {
        accountType.lowercased() == "vendor" &&
        vendorId > 0
    }

    private var serviceOptions: [String] {
        let vendorCategories = vendorOptions
        .compactMap {
            $0.category?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
        .filter { !$0.isEmpty }

        return Array(
            Set(
                vendorCategories +
                fallbackServiceOptions
            )
        )
        .sorted()
    }

    private var filteredVendorOptions: [Vendor] {
        let cleanService = selectedService
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased()

        return vendorOptions.filter { vendor in
            let cleanCategory =
            (vendor.category ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

            return cleanCategory == cleanService
        }
    }

    var body: some View {
        Group {
            if isVendorAccount {
                VendorRequestsView()
            } else {
                residentContactView
            }
        }
    }

    private var residentContactView: some View {
        NeonBackground {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    Text("Contact")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    NeonCard(
                        title: "Need Help?",
                        text:
                        "Select a service, choose a vendor, and send your request directly to that vendor."
                    )

                    residentRequestsSection

                    helpFormCard

                    Link(
                        "Call Clubhouse Links",
                        destination: URL(
                            string: "tel:2145489175"
                        )!
                    )
                    .font(.headline)
                    .foregroundStyle(.cyan)

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .scrollDismissesKeyboard(
                .interactively
            )
        }
        .onAppear {
            loadVendorOptions()
        }
        .task(id: residentId) {
            await loadResidentRequests()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else {
                return
            }

            Task {
                await loadResidentRequests()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                .residentServiceRequestStatusChanged
            )
        ) { _ in
            Task {
                await loadResidentRequests()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                .residentServiceRequestNotificationTapped
            )
        ) { _ in
            Task {
                await loadResidentRequests()
            }
        }
        .onChange(of: selectedService) { _ in
            selectFirstVendorForService()
        }
        .onChange(of: selectedVendorId) { _ in
            syncServiceToSelectedVendor()
        }
    }

    @ViewBuilder
    private var residentRequestsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack(alignment: .center) {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Your Service Requests")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                    Text(
                        "Track requests you have sent to local vendors."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.68)
                    )
                }

                Spacer()

                Button {
                    Task {
                        await loadResidentRequests()
                    }
                } label: {
                    Image(
                        systemName:
                        "arrow.clockwise"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(.cyan)
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .background(
                        .black.opacity(0.22)
                    )
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(residentRequestsLoading)
            }

            if residentRequestsLoading &&
            residentRequests.isEmpty {

                HStack(spacing: 10) {
                    ProgressView()
                    .tint(.cyan)

                    Text(
                        "Loading service requests..."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.72)
                    )
                }
                .padding(.vertical, 12)

            } else if !residentRequestsError.isEmpty &&
            residentRequests.isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    Label(
                        "Could not load requests",
                        systemImage:
                        "exclamationmark.triangle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.orange)

                    Text(residentRequestsError)
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.72)
                    )

                    Button("Try Again") {
                        Task {
                            await loadResidentRequests()
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)
                }

            } else if residentRequests.isEmpty {
                VStack(spacing: 10) {
                    Image(
                        systemName:
                        "paperplane.circle.fill"
                    )
                    .font(.system(size: 42))
                    .foregroundStyle(.cyan)

                    Text("No service requests yet")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                    Text(
                        "Your request and its current status will appear here after you submit it."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.68)
                    )
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)

            } else {
                VStack(spacing: 12) {
                    ForEach(
                        Array(
                            residentRequests.prefix(5)
                        )
                    ) { request in
                        ResidentServiceRequestStatusCard(
                            request: request
                        )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.13),
                    .purple.opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.55),
                lineWidth: 1
            )
        )
    }

    private var helpFormCard: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            Text("Request a Service")
            .font(.title2.bold())
            .foregroundStyle(.white)

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker(
                    "Service",
                    selection: $selectedService
                ) {
                    ForEach(
                        serviceOptions,
                        id: \.self
                    ) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Vendor")
                .font(.headline)
                .foregroundStyle(.cyan)

                if vendorOptionsLoading {
                    ProgressView()
                    .tint(.cyan)
                    .padding(.vertical, 12)
                } else if !vendorOptionsError.isEmpty {
                    Text(vendorOptionsError)
                    .font(.caption)
                    .foregroundStyle(
                        .red.opacity(0.9)
                    )
                } else if filteredVendorOptions.isEmpty {
                    Text(
                        "No vendors found for this service."
                    )
                    .font(.caption.bold())
                    .foregroundStyle(
                        .white.opacity(0.65)
                    )
                } else {
                    Picker(
                        "Vendor",
                        selection: $selectedVendorId
                    ) {
                        ForEach(
                            filteredVendorOptions
                        ) { vendor in
                            Text(vendor.company_name)
                            .tag(vendor.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        .black.opacity(0.22)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Message")
                .font(.headline)
                .foregroundStyle(.cyan)

                TextField(
                    "Describe what you need",
                    text: $message,
                    axis: .vertical
                )
                .lineLimit(4...7)
                .padding()
                .foregroundStyle(.white)
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                    .stroke(
                        .cyan.opacity(0.5),
                        lineWidth: 1
                    )
                )
            }

            Button {
                submitHelpRequest()
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                        .tint(.white)
                    }

                    Text(
                        isSubmitting
                        ? "Sending..."
                        : "Submit"
                    )
                    .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            .purple,
                            .orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .shadow(
                    color: .cyan.opacity(0.35),
                    radius: 10
                )
            }
            .disabled(
                isSubmitting ||
                vendorOptionsLoading
            )
            .opacity(
                isSubmitting ||
                vendorOptionsLoading
                ? 0.65
                : 1
            )

            if !submitMessage.isEmpty {
                Text(submitMessage)
                .font(.subheadline.bold())
                .foregroundStyle(
                    submitMessage
                    .lowercased()
                    .contains("sent")
                    ? .cyan
                    : .red
                )
                .multilineTextAlignment(
                    .center
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.13),
                    .purple.opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.55),
                lineWidth: 1
            )
        )
    }

    @MainActor
    private func loadResidentRequests() async {
        guard residentId > 0 else {
            residentRequests = []
            residentRequestsError =
            "Resident profile not found."
            residentRequestsLoading = false
            return
        }

        guard !residentRequestsLoading else {
            return
        }

        residentRequestsLoading = true
        residentRequestsError = ""

        defer {
            residentRequestsLoading = false
        }

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/residents/" +
        "\(residentId)/service-requests"

        guard let url = URL(
            string: urlString
        ) else {
            residentRequestsError =
            "Invalid service-request URL."
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "no-cache",
            forHTTPHeaderField:
            "Cache-Control"
        )

        do {
            let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse =
            response as? HTTPURLResponse else {
                residentRequestsError =
                "Invalid response from server."
                return
            }

            let decoded =
            try JSONDecoder().decode(
                ResidentServiceRequestsResponse.self,
                from: data
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ),
            decoded.success == true else {
                residentRequestsError =
                decoded.error ??
                "Could not load service requests."
                return
            }

            residentRequests =
            decoded.requests ?? []
        } catch is CancellationError {
            return
        } catch let error as URLError
        where error.code == .cancelled {
            return
        } catch {
            residentRequestsError =
            error.localizedDescription
        }
    }

    private func loadVendorOptions() {
        guard residentId > 0 else {
            vendorOptionsError =
            "Resident profile not found."
            return
        }

        vendorOptionsLoading = true
        vendorOptionsError = ""

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/vendors/\(residentId)"

        guard let url = URL(
            string: urlString
        ) else {
            vendorOptionsLoading = false
            vendorOptionsError =
            "Invalid vendor URL."
            return
        }

        URLSession.shared.dataTask(
            with: url
        ) { data, _, error in
            DispatchQueue.main.async {
                vendorOptionsLoading = false

                if let error {
                    vendorOptionsError =
                    error.localizedDescription
                    return
                }

                guard let data else {
                    vendorOptionsError =
                    "No vendors found."
                    return
                }

                do {
                    let decoded =
                    try JSONDecoder().decode(
                        VendorResponse.self,
                        from: data
                    )

                    guard decoded.success == true else {
                        vendorOptionsError =
                        decoded.error ??
                        "Could not load vendors."
                        return
                    }

                    vendorOptions =
                    decoded.vendors ?? []

                    if let firstVendor =
                    vendorOptions.first {
                        selectedVendorId =
                        firstVendor.id
                        selectedService =
                        firstVendor.category ??
                        selectedService
                    }
                } catch {
                    vendorOptionsError =
                    String(
                        data: data,
                        encoding: .utf8
                    ) ??
                    "Could not decode vendors."
                }
            }
        }
        .resume()
    }

    private func selectFirstVendorForService() {
        guard let firstVendor =
        filteredVendorOptions.first else {
            selectedVendorId = 0
            return
        }

        if !filteredVendorOptions.contains(
            where: {
                $0.id == selectedVendorId
            }
        ) {
            selectedVendorId =
            firstVendor.id
        }
    }

    private func syncServiceToSelectedVendor() {
        guard let vendor =
        selectedVendor() else {
            return
        }

        if let category = vendor.category,
        !category.isEmpty {
            selectedService = category
        }
    }

    private func selectedVendor() -> Vendor? {
        vendorOptions.first {
            $0.id == selectedVendorId
        }
    }

    private func submitHelpRequest() {
        guard !isSubmitting else {
            return
        }

        let cleanMessage =
        message.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard residentId > 0 else {
            submitMessage =
            "Resident profile not found."
            return
        }

        guard selectedVendorId > 0 else {
            submitMessage =
            "Please select a vendor."
            return
        }

        guard !cleanMessage.isEmpty else {
            submitMessage =
            "Please enter a message."
            return
        }

        let payload =
        ResidentServiceRequestPayload(
            vendor_id: selectedVendorId,
            service: selectedService,
            sub_service: nil,
            message: cleanMessage
        )

        isSubmitting = true
        submitMessage = ""

        Task {
            do {
                let response =
                try await VendorAPI.shared
                .submitResidentRequest(
                    residentId: residentId,
                    payload: payload
                )

                await MainActor.run {
                    let vendorName =
                    selectedVendor()?
                    .company_name ??
                    "the selected vendor"

                    submitMessage =
                    response.message ??
                    "Your request was sent to \(vendorName)."

                    message = ""
                    isSubmitting = false
                }

                await loadResidentRequests()
            } catch {
                await MainActor.run {
                    submitMessage =
                    error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}


private struct ResidentServiceRequestStatusCard:
View {

    let request:
    ResidentServiceRequestStatusItem

    private var vendorName: String {
        let cleaned =
        request.vendor_company_name?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        return cleaned.isEmpty
        ? "Local Vendor"
        : cleaned
    }

    private var serviceName: String {
        let cleaned =
        request.service
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return cleaned.isEmpty
        ? "Service Request"
        : cleaned
    }

    private var statusTitle: String {
        switch request.status.lowercased() {
        case "new":
            return "Sent"

        case "viewed":
            return "Viewed"

        case "accepted":
            return "Accepted"

        case "declined":
            return "Declined"

        case "completed":
            return "Completed"

        case "cancelled":
            return "Cancelled"

        default:
            return request.status.capitalized
        }
    }

    private var statusSymbol: String {
        switch request.status.lowercased() {
        case "new":
            return "paperplane.fill"

        case "viewed":
            return "eye.fill"

        case "accepted":
            return "checkmark.circle.fill"

        case "declined":
            return "xmark.circle.fill"

        case "completed":
            return "checkmark.seal.fill"

        case "cancelled":
            return "nosign"

        default:
            return "clock.fill"
        }
    }

    private var statusColor: Color {
        switch request.status.lowercased() {
        case "accepted",
        "completed":
            return .green

        case "declined",
        "cancelled":
            return .red

        case "viewed":
            return .cyan

        default:
            return .orange
        }
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 14
        ) {
            vendorLogo

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text(vendorName)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)

                Text(serviceName)
                .font(.subheadline.bold())
                .foregroundStyle(.cyan)

                if !request.message
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {

                    Text(request.message)
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.70)
                    )
                    .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Label(
                        statusTitle,
                        systemImage: statusSymbol
                    )
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)

                    if let date =
                    formattedDate(
                        request.created_at
                    ) {
                        Text("•")
                        .foregroundStyle(
                            .white.opacity(0.45)
                        )

                        Text(date)
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.58)
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            .black.opacity(0.20)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                statusColor.opacity(0.48),
                lineWidth: 1
            )
        )
    }

    @ViewBuilder
    private var vendorLogo: some View {
        if let logoValue =
        request.vendor_logo_url?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ),
        !logoValue.isEmpty,
        let logoURL =
        URL(string: logoValue) {

            AsyncImage(url: logoURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                    .tint(.cyan)

                case .success(let image):
                    image
                    .resizable()
                    .scaledToFit()
                    .padding(5)

                case .failure:
                    defaultLogo

                @unknown default:
                    defaultLogo
                }
            }
            .frame(width: 66, height: 66)
            .background(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        } else {
            defaultLogo
            .frame(width: 66, height: 66)
            .background(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
    }

    private var defaultLogo: some View {
        Image("clubhouse_logo")
        .resizable()
        .scaledToFit()
        .padding(5)
    }

    private func formattedDate(
    _ value: String?
    ) -> String? {
        guard let value,
        !value.isEmpty else {
            return nil
        }

        let withFractions =
        ISO8601DateFormatter()

        withFractions.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let regular =
        ISO8601DateFormatter()

        guard let date =
        withFractions.date(
            from: value
        ) ??
        regular.date(
            from: value
        ) else {
            return nil
        }

        return date.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }
}
