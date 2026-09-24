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

    @AppStorage("supportResidentMode")
    private var supportResidentMode = false

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

    @State
    private var incomingNeighborRequests:
    [NeighborContactRequest] = []

    @State
    private var outgoingNeighborRequests:
    [NeighborContactRequest] = []

    @State
    private var neighborRequestsLoading = false

    @State
    private var neighborRequestsError = ""

    @State
    private var respondingNeighborRequestIds:
    Set<Int> = []

    @State
    private var neighborRequestMessage = ""

    let preselectedVendorId: Int?
    let preselectedService: String?


    init(
    preselectedVendorId: Int? = nil,
    preselectedService: String? = nil
    ) {

        self.preselectedVendorId =
        preselectedVendorId

        self.preselectedService =
        preselectedService
    }
    private func neighborRequestGroupTitle(
    _ title:
    String,
    systemImage:
    String,
    count:
    Int
    ) -> some View {

        HStack(
            spacing:
            8
        ) {

            Image(
                systemName:
                systemImage
            )
            .foregroundStyle(
                .orange
            )

            Text(
                title
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .white
            )

            Text(
                "\(count)"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                .black
            )
            .padding(
                .horizontal,
                8
            )
            .padding(
                .vertical,
                3
            )
            .background(
                .orange
            )
            .clipShape(
                Capsule()
            )

            Spacer()
        }
    }

    private func incomingNeighborRequestCard(
    _ request:
    NeighborContactRequest
    ) -> some View {

        VStack(
            alignment:
            .leading,
            spacing:
            12
        ) {

            HStack(
                alignment:
                .top
            ) {

                VStack(
                    alignment:
                    .leading,
                    spacing:
                    4
                ) {

                    Text(
                        neighborDisplayName(
                            first:
                            request.requester_first_name,
                            last:
                            request.requester_last_name
                        )
                    )
                    .font(
                        .headline.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    if let vendor =
                    request.vendor_name {

                        Text(
                            "About \(vendor)"
                        )
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }


                    if let address =
                    cleanedText(
                        request.requester_address
                    ) {

                        Label(
                            address,
                            systemImage:
                            "house.fill"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.65
                            )
                        )
                    }
                }


                Spacer()


                requestStatusBadge(
                    request.status
                )
            }


            if let message =
            cleanedText(
                request.message
            ) {

                Text(
                    message
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.78
                    )
                )
            }


            let status =
            request.status?
            .lowercased() ??
            ""


            if status ==
            "pending" {

                HStack(
                    spacing:
                    10
                ) {

                    Button {

                        Task {

                            await respondToNeighborRequest(
                                request,
                                action:
                                "decline"
                            )
                        }

                    } label: {

                        Text(
                            "Decline"
                        )
                        .font(
                            .headline.bold()
                        )
                        .foregroundStyle(
                            .white
                        )
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .padding(
                            .vertical,
                            11
                        )
                        .background(
                            .red.opacity(
                                0.55
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                12
                            )
                        )
                    }
                    .buttonStyle(
                        .plain
                    )


                    Button {

                        Task {

                            await respondToNeighborRequest(
                                request,
                                action:
                                "accept"
                            )
                        }

                    } label: {

                        if respondingNeighborRequestIds
                        .contains(
                            request.id
                        ) {

                            ProgressView()
                            .tint(
                                .white
                            )
                            .frame(
                                maxWidth:
                                .infinity
                            )
                            .padding(
                                .vertical,
                                11
                            )

                        } else {

                            Text(
                                "Accept"
                            )
                            .font(
                                .headline.bold()
                            )
                            .foregroundStyle(
                                .white
                            )
                            .frame(
                                maxWidth:
                                .infinity
                            )
                            .padding(
                                .vertical,
                                11
                            )
                        }
                    }
                    .background(
                        .green.opacity(
                            0.65
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                            12
                        )
                    )
                    .buttonStyle(
                        .plain
                    )
                }
                .disabled(
                    respondingNeighborRequestIds
                    .contains(
                        request.id
                    )
                )

            } else if
            status ==
            "accepted",
            let phone =
            cleanedText(
                request.requester_phone
            ) {

                neighborPhoneButton(
                    name:
                    request.requester_first_name ??
                    "Neighbor",
                    phone:
                    phone
                )
            }
        }
        .padding(
            15
        )
        .background(
            .black.opacity(
                0.22
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                18
            )
        )
    }

    private func outgoingNeighborRequestCard(
    _ request:
    NeighborContactRequest
    ) -> some View {

        VStack(
            alignment:
            .leading,
            spacing:
            12
        ) {

            HStack(
                alignment:
                .top
            ) {

                VStack(
                    alignment:
                    .leading,
                    spacing:
                    4
                ) {

                    Text(
                        neighborDisplayName(
                            first:
                            request.target_first_name,
                            last:
                            request.target_last_name
                        )
                    )
                    .font(
                        .headline.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    if let vendor =
                    request.vendor_name {

                        Text(
                            "About \(vendor)"
                        )
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }


                    if let address =
                    cleanedText(
                        request.target_address
                    ) {

                        Label(
                            address,
                            systemImage:
                            "house.fill"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.65
                            )
                        )
                    }
                }


                Spacer()


                requestStatusBadge(
                    request.status
                )
            }


            if let message =
            cleanedText(
                request.message
            ) {

                Text(
                    message
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.78
                    )
                )
            }


            if request.status?
            .lowercased() ==
            "accepted",
            let phone =
            cleanedText(
                request.target_phone
            ) {

                neighborPhoneButton(
                    name:
                    request.target_first_name ??
                    "Neighbor",
                    phone:
                    phone
                )
            }
        }
        .padding(
            15
        )
        .background(
            .black.opacity(
                0.22
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                18
            )
        )
    }

    private var sortedIncomingNeighborRequests:
    [NeighborContactRequest] {

        incomingNeighborRequests.sorted {
            left,
            right in

            let leftPending =
            left.status?
            .lowercased() ==
            "pending"

            let rightPending =
            right.status?
            .lowercased() ==
            "pending"

            if leftPending !=
            rightPending {

                return leftPending
            }

            return left.id >
            right.id
        }
    }


    private var sortedOutgoingNeighborRequests:
    [NeighborContactRequest] {

        outgoingNeighborRequests.sorted {
            $0.id > $1.id
        }
    }
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

        /*
         * Aspen remains a vendor underneath,
         * but while supportResidentMode is active
         * the UI should behave like the resident.
         */
        if supportResidentMode && residentId > 0 {
            return false
        }

        return accountType
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased() == "vendor"
        &&
        vendorId > 0
    }
    private var serviceOptions: [String] {
        let vendorCategories = vendorOptions.flatMap { vendor in
            services(for: vendor)
        }

        let normalizedFallbacks = fallbackServiceOptions.map {
            canonicalService($0)
        }

        let allServiceKeys = Set(
            vendorCategories + normalizedFallbacks
        )

        return allServiceKeys
        .map(displayServiceName)
        .sorted()
    }

    private var filteredVendorOptions: [Vendor] {
        let selectedKey = canonicalService(selectedService)

        let matchingVendors = vendorOptions.filter { vendor in
            services(for: vendor).contains(selectedKey)
        }

        var seenCompanies = Set<String>()

        return matchingVendors.filter { vendor in
            let companyKey = vendor.company_name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

            guard !seenCompanies.contains(companyKey) else {
                return false
            }

            seenCompanies.insert(companyKey)
            return true
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

                    neighborContactRequestsSection

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
            .refreshable {

                await loadAllResidentRequests()
            }
            .scrollDismissesKeyboard(
                .interactively
            )
        }
        .onAppear {
            loadVendorOptions()
        }
        .task(id: residentId) {

            await loadAllResidentRequests()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else {
                return
            }

            Task {
                await loadAllResidentRequests()
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

        .onReceive(
            NotificationCenter.default.publisher(
                for:
                .neighborContactRequestChanged
            )
        ) { _ in

            Task {
                await loadNeighborContactRequests()
            }
        }

        .onReceive(
            NotificationCenter.default.publisher(
                for:
                .neighborContactRequestNotificationTapped
            )
        ) { _ in

            Task {
                await loadNeighborContactRequests()
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
    private func requestStatusBadge(
    _ rawStatus: String?
    ) -> some View {

        let status =
        rawStatus?
        .lowercased() ??
        "pending"

        let title: String
        let icon: String
        let color: Color

        switch status {

        case "accepted":
            title = "Accepted"
            icon = "checkmark.circle.fill"
            color = .green

        case "declined":
            title = "Declined"
            icon = "xmark.circle.fill"
            color = .red

        default:
            title = "Pending"
            icon = "clock.fill"
            color = .orange
        }

        return Label(
            title,
            systemImage: icon
        )
        .font(
            .caption.bold()
        )
        .foregroundStyle(
            color
        )
    }


    private func neighborPhoneButton(
    name:
    String,
    phone:
    String
    ) -> some View {

        let digits =
        phone.filter {
            $0.isNumber
        }


        return Link(
            destination:
            URL(
                string:
                "tel:\(digits)"
            )!
        ) {

            HStack {

                Image(
                    systemName:
                    "phone.fill"
                )

                Text(
                    "Call \(name) • \(formatNeighborPhone(phone))"
                )
                .font(
                    .subheadline.bold()
                )

                Spacer()
            }
            .foregroundStyle(
                .white
            )
            .padding(
                12
            )
            .background(
                .green.opacity(
                    0.55
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                    12
                )
            )
        }
    }


    private func cleanedText(
    _ value:
    String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let clean =
        value
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        )

        return clean.isEmpty
        ? nil
        : clean
    }


    private func neighborDisplayName(
    first:
    String?,
    last:
    String?
    ) -> String {

        let values =
        [
            first,
            last
        ]
        .compactMap {
            cleanedText(
                $0
            )
        }

        return values.isEmpty
        ? "Neighbor"
        : values.joined(
            separator:
            " "
        )
    }


    private func formatNeighborPhone(
    _ phone:
    String
    ) -> String {

        var digits =
        phone.filter {
            $0.isNumber
        }

        if
        digits.count ==
        11,
        digits.first ==
        "1" {

            digits.removeFirst()
        }


        guard
        digits.count ==
        10
        else {

            return phone
        }


        return
        "(\(digits.prefix(3))) " +
        "\(digits.dropFirst(3).prefix(3))-" +
        "\(digits.suffix(4))"
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
    @ViewBuilder
    private var neighborContactRequestsSection:
    some View {

        VStack(
            alignment:
            .leading,
            spacing:
            16
        ) {

            HStack {

                VStack(
                    alignment:
                    .leading,
                    spacing:
                    4
                ) {

                    Text(
                        "Neighbor Contact Requests"
                    )
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    Text(
                        "Ask neighbors about companies they have used."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.68
                        )
                    )
                }


                Spacer()


                Button {

                    Task {

                        await loadNeighborContactRequests()
                    }

                } label: {

                    Image(
                        systemName:
                        "arrow.clockwise"
                    )
                    .font(
                        .headline.bold()
                    )
                    .foregroundStyle(
                        .cyan
                    )
                    .frame(
                        width:
                        42,
                        height:
                        42
                    )
                    .background(
                        .black.opacity(
                            0.22
                        )
                    )
                    .clipShape(
                        Circle()
                    )
                }
                .buttonStyle(
                    .plain
                )
                .disabled(
                    neighborRequestsLoading
                )
            }


            if neighborRequestsLoading &&
            incomingNeighborRequests.isEmpty &&
            outgoingNeighborRequests.isEmpty {

                HStack(
                    spacing:
                    10
                ) {

                    ProgressView()
                    .tint(
                        .cyan
                    )

                    Text(
                        "Loading neighbor requests..."
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.72
                        )
                    )
                }
                .padding(
                    .vertical,
                    12
                )

            } else if
            !neighborRequestsError.isEmpty &&
            incomingNeighborRequests.isEmpty &&
            outgoingNeighborRequests.isEmpty {

                VStack(
                    alignment:
                    .leading,
                    spacing:
                    8
                ) {

                    Label(
                        "Could not load neighbor requests",
                        systemImage:
                        "exclamationmark.triangle.fill"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        .orange
                    )


                    Text(
                        neighborRequestsError
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.68
                        )
                    )
                }

            } else if
            incomingNeighborRequests.isEmpty &&
            outgoingNeighborRequests.isEmpty {

                VStack(
                    spacing:
                    10
                ) {

                    Image(
                        systemName:
                        "person.2.circle.fill"
                    )
                    .font(
                        .system(
                            size:
                            42
                        )
                    )
                    .foregroundStyle(
                        .cyan
                    )


                    Text(
                        "No neighbor requests yet"
                    )
                    .font(
                        .headline.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    Text(
                        "Requests to speak with neighbors about local vendors will appear here."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.68
                        )
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
                .frame(
                    maxWidth:
                    .infinity
                )
                .padding(
                    .vertical,
                    18
                )

            } else {

                if !incomingNeighborRequests.isEmpty {

                    neighborRequestGroupTitle(
                        "Incoming",
                        systemImage:
                        "tray.and.arrow.down.fill",
                        count:
                        incomingNeighborRequests.count
                    )


                    VStack(
                        spacing:
                        12
                    ) {

                        ForEach(
                            sortedIncomingNeighborRequests
                        ) {
                            request in

                            incomingNeighborRequestCard(
                                request
                            )
                        }
                    }
                }


                if !outgoingNeighborRequests.isEmpty {

                    neighborRequestGroupTitle(
                        "Sent",
                        systemImage:
                        "paperplane.fill",
                        count:
                        outgoingNeighborRequests.count
                    )
                    .padding(
                        .top,
                        incomingNeighborRequests.isEmpty
                        ? 0
                        : 8
                    )


                    VStack(
                        spacing:
                        12
                    ) {

                        ForEach(
                            sortedIncomingNeighborRequests
                        ) {
                            request in

                            outgoingNeighborRequestCard(
                                request
                            )
                        }
                    }
                }
            }


            if !neighborRequestMessage.isEmpty {

                Text(
                    neighborRequestMessage
                )
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    .cyan
                )
            }
        }
        .padding(
            18
        )
        .frame(
            maxWidth:
            .infinity
        )
        .background(
            LinearGradient(
                colors: [
                    .orange.opacity(
                        0.10
                    ),
                    .purple.opacity(
                        0.24
                    )
                ],
                startPoint:
                .topLeading,
                endPoint:
                .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                28
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius:
                28
            )
            .stroke(
                .orange.opacity(
                    0.45
                ),
                lineWidth:
                1
            )
        }
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
                        ForEach(filteredVendorOptions) { vendor in
                            HStack(spacing: 6) {
                                Text(vendor.company_name)

                                if (vendor.signup_count ?? 0) > 0 {
                                    Image(systemName: "star.fill")

                                    Text("\(vendor.signup_count ?? 0)")
                                    .fontWeight(.bold)
                                }
                            }
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

            vendorActivitySection

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Message")
                .font(.headline)
                .foregroundStyle(.cyan)

                TextField(
                    "Describe what you need. What day works best for you?",
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
    @ViewBuilder
    private var vendorActivitySection: some View {
        if let vendor = selectedVendor(),
        (vendor.signup_count ?? 0) > 0 {

            VStack(alignment: .leading, spacing: 16) {

                // Gold star + homeowner activity count
                HStack(spacing: 14) {
                    Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        let count = vendor.signup_count ?? 0

                        Text(
                            "\(count) " +
                            (count == 1 ? "homeowner" : "homeowners")
                        )
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                        Text(
                            "\(count) " +
                            (count == 1
                            ? "homeowner has"
                            : "homeowners have") +
                            " used or submitted work with " +
                            "\(vendor.company_name)."
                        )
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                    }

                    Spacer()
                }

                // Completed project carousel for THIS vendor
                if let projects = vendor.nearby_completed_projects,
                !projects.isEmpty {

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Completed Projects Near You")
                        .font(.headline.bold())
                        .foregroundStyle(.cyan)

                        TabView {
                            ForEach(
                                Array(projects.prefix(5))
                            ) { project in
                                nearbyVendorProjectSlide(
                                    project,
                                    vendor: vendor
                                )
                                .padding(.horizontal, 4)
                            }
                        }
                        .frame(height: 200)
                        .tabViewStyle(
                            .page(
                                indexDisplayMode: .automatic
                            )
                        )
                    }
                }
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                LinearGradient(
                    colors: [
                        .yellow.opacity(0.10),
                        .orange.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                .stroke(
                    .yellow.opacity(0.55),
                    lineWidth: 1
                )
            )
        }
    }

    private func nearbyVendorProjectSlide(
    _ project: VendorNearbyCompletedProject,
    vendor: Vendor
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 12) {

                // Finished project photo
                if let imageUrl = project.finished_photo_url,
                !imageUrl.isEmpty,
                let url = URL(string: imageUrl) {

                    AsyncImage(url: url) { phase in
                        switch phase {

                        case .empty:
                            ZStack {
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                                .fill(.black.opacity(0.25))

                                ProgressView()
                                .tint(.cyan)
                            }

                        case .success(let image):
                            image
                            .resizable()
                            .scaledToFill()

                        case .failure:
                            ZStack {
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                                .fill(.black.opacity(0.25))

                                Image(
                                    systemName:
                                    "house.and.flag.fill"
                                )
                                .font(.title)
                                .foregroundStyle(.cyan)
                            }

                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(
                        width: 110,
                        height: 90
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )

                } else {

                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                        .fill(.black.opacity(0.25))

                        Image(
                            systemName:
                            "house.and.flag.fill"
                        )
                        .font(.title)
                        .foregroundStyle(.cyan)
                    }
                    .frame(
                        width: 110,
                        height: 90
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(vendor.company_name)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                    Text(selectedService)
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)

                    if let firstName = project.first_name,
                    !firstName.isEmpty {

                        Text(
                            "\(firstName) used this contractor"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.75)
                        )
                        .lineLimit(1)
                    }

                    if let distance =
                    project.distance_miles {

                        Text(
                            String(
                                format:
                                "%.1f miles away",
                                distance
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                    }
                }

                Spacer(minLength: 0)
            }

            if let address = project.address,
            !address.isEmpty {

                Text(address)
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.55)
                )
                .lineLimit(1)
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .black.opacity(0.18)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
            .stroke(
                .purple.opacity(0.45),
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

    @MainActor
    private func loadAllResidentRequests()
    async {

        await loadResidentRequests()

        await loadNeighborContactRequests()
    }
    @MainActor
    private func loadNeighborContactRequests()
    async {

        guard residentId > 0 else {

            incomingNeighborRequests =
            []

            outgoingNeighborRequests =
            []

            neighborRequestsError =
            "Resident profile not found."

            return
        }


        guard !neighborRequestsLoading
        else {
            return
        }


        neighborRequestsLoading =
        true

        neighborRequestsError =
        ""


        defer {

            neighborRequestsLoading =
            false
        }


        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/residents/" +
        "\(residentId)/neighbor-contact-requests"


        guard let url =
        URL(
            string:
            urlString
        )
        else {

            neighborRequestsError =
            "Invalid neighbor-request URL."

            return
        }


        var request =
        URLRequest(
            url:
            url
        )

        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "no-cache",
            forHTTPHeaderField:
            "Cache-Control"
        )


        do {

            let (
            data,
            response
            ) =
            try await URLSession
            .shared
            .data(
                for:
                request
            )


            guard let httpResponse =
            response
            as?
            HTTPURLResponse
            else {

                neighborRequestsError =
                "Invalid response from server."

                return
            }


            let decoded =
            try JSONDecoder()
            .decode(
                NeighborContactRequestsResponse.self,
                from:
                data
            )


            guard
            (200...299)
            .contains(
                httpResponse.statusCode
            ),
            decoded.success ==
            true
            else {

                neighborRequestsError =
                decoded.error ??
                "Could not load neighbor requests."

                return
            }


            incomingNeighborRequests =
            decoded.incoming ??
            []

            outgoingNeighborRequests =
            decoded.outgoing ??
            []

        } catch is CancellationError {

            return

        } catch let error
        as URLError
        where error.code ==
        .cancelled {

            return

        } catch {

            neighborRequestsError =
            error.localizedDescription
        }
    }

    @MainActor
    private func respondToNeighborRequest(
    _ contactRequest:
    NeighborContactRequest,
    action:
    String
    ) async {

        guard residentId > 0 else {
            return
        }


        guard
        action ==
        "accept" ||
        action ==
        "decline"
        else {
            return
        }


        respondingNeighborRequestIds
        .insert(
            contactRequest.id
        )


        neighborRequestMessage =
        ""


        defer {

            respondingNeighborRequestIds
            .remove(
                contactRequest.id
            )
        }


        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/residents/" +
        "\(residentId)/neighbor-contact-requests/" +
        "\(contactRequest.id)/respond"


        guard let url =
        URL(
            string:
            urlString
        )
        else {

            neighborRequestMessage =
            "Could not respond to the request."

            return
        }


        var request =
        URLRequest(
            url:
            url
        )

        request.httpMethod =
        "PATCH"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Accept"
        )


        do {

            request.httpBody =
            try JSONSerialization
            .data(
                withJSONObject: [
                    "action":
                    action
                ]
            )


            let (
            data,
            response
            ) =
            try await URLSession
            .shared
            .data(
                for:
                request
            )


            guard let httpResponse =
            response
            as?
            HTTPURLResponse
            else {

                neighborRequestMessage =
                "Invalid server response."

                return
            }


            if
            (200...299)
            .contains(
                httpResponse.statusCode
            ) {

                neighborRequestMessage =
                action ==
                "accept"
                ? "Contact request accepted."
                : "Contact request declined."

                await loadNeighborContactRequests()

                return
            }


            if let object =
            try?
            JSONSerialization
            .jsonObject(
                with:
                data
            )
            as?
            [String: Any],
            let error =
            object["error"]
            as?
            String {

                neighborRequestMessage =
                error

            } else {

                neighborRequestMessage =
                "Could not update the request."
            }

        } catch {

            neighborRequestMessage =
            error.localizedDescription
        }
    }
    private func canonicalService(_ raw: String) -> String {
        let value = raw
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "-", with: "_")
        .replacingOccurrences(of: " ", with: "_")

        switch value {
        case "roofing", "roofer", "roofing_contractor":
            return "roofer"

        case "general_contractor", "generalcontractor":
            return "general_contractor"

        default:
            return value
        }
    }

    private func displayServiceName(_ key: String) -> String {
        switch canonicalService(key) {
        case "roofer":
            return "Roofing"

        case "general_contractor":
            return "General Contractor"

        case "pool_service":
            return "Pool Service"

        default:
            return key
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
        }
    }

    private func services(for vendor: Vendor) -> [String] {
        if let categories = vendor.categories,
        !categories.isEmpty {
            return categories.map(canonicalService)
        }

        if let category = vendor.category,
        !category.isEmpty {
            return [canonicalService(category)]
        }

        return []
    }
    private func applyInitialVendorSelection() {

        /*
         * Street Fair sent us directly here
         * with a specific contractor.
         */
        if let preferredVendorId =
        preselectedVendorId,
        let preferredVendor =
        vendorOptions.first(
            where: {
                $0.id == preferredVendorId
            }
        ) {

            selectedVendorId =
            preferredVendor.id

            let vendorServices =
            services(
                for: preferredVendor
            )


            /*
             * Use the requested service if the
             * vendor actually supports it.
             */
            if let preferredService =
            preselectedService,
            !preferredService.isEmpty {

                let preferredKey =
                canonicalService(
                    preferredService
                )

                if vendorServices.contains(
                    preferredKey
                ) {

                    selectedService =
                    displayServiceName(
                        preferredKey
                    )

                    return
                }
            }


            /*
             * Otherwise use this contractor's
             * first service.
             */
            if let firstService =
            vendorServices.first {

                selectedService =
                displayServiceName(
                    firstService
                )
            }

            return
        }


        /*
         * Normal Service Requests screen:
         * preserve the current behavior.
         */
        if let firstVendor =
        vendorOptions.first {

            selectedVendorId =
            firstVendor.id

            if let firstService =
            services(
                for: firstVendor
            ).first {

                selectedService =
                displayServiceName(
                    firstService
                )
            }
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

                    applyInitialVendorSelection()

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
        guard let vendor = selectedVendor() else {
            return
        }

        let selectedKey = canonicalService(selectedService)
        let vendorServices = services(for: vendor)

        if vendorServices.contains(selectedKey) {
            return
        }

        if let firstService = vendorServices.first {
            selectedService = displayServiceName(firstService)
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
            service: canonicalService(selectedService),
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
