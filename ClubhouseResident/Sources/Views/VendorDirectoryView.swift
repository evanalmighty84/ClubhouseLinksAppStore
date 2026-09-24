import SwiftUI
import Foundation


// MARK: - Vendor API Models

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
    let nearby_completed_projects:
    [VendorNearbyCompletedProject]?
    let signed_up_people:
    [VendorSignupPerson]?
}


struct VendorSignupPerson:
Codable,
Identifiable {

    let id: Int
    let first_name: String?
    let address: String?
    let distance_miles: Double?
    let finished_photo_url: String?
    let photo_approval_status: String?
}


// MARK: - Neighbor Contact Models

struct NeighborContactRequestsResponse:
Codable {

    let success: Bool?
    let incoming:
    [NeighborContactRequest]?
    let outgoing:
    [NeighborContactRequest]?
    let incoming_count: Int?
    let outgoing_count: Int?
    let error: String?
}


struct NeighborContactRequest:
Codable,
Identifiable {

    let id: Int

    let requester_resident_id: Int?
    let target_resident_id: Int?
    let vendor_id: Int?

    let message: String?
    let status: String?

    let vendor_name: String?
    let vendor_category: String?
    let vendor_logo_url: String?

    let target_first_name: String?
    let target_last_name: String?
    let target_address: String?
    let target_phone: String?

    let requester_first_name: String?
    let requester_last_name: String?
    let requester_address: String?
    let requester_phone: String?

    let same_hoa: Bool?

    let created_at: String?
    let responded_at: String?
    let updated_at: String?
}


struct NeighborContactCreateResponse:
Codable {

    let success: Bool?
    let request:
    NeighborContactRequest?
    let message: String?
    let error: String?
}


// MARK: - Vendor Directory

struct VendorDirectoryView: View {

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentFirstName")
    private var firstName = ""

    @AppStorage("residentLastName")
    private var lastName = ""

    @AppStorage("residentNeighborhoodName")
    private var neighborhoodName = ""

    @AppStorage("residentDisplayAreaName")
    private var displayAreaName = ""


    @State
    private var vendors:
    [Vendor] = []

    @State
    private var isLoading = true

    @State
    private var errorMessage = ""

    @State
    private var selectedService = ""

    @State
    private var selectedNeighborVendor:
    Vendor?

    @State
    private var outgoingContactRequests:
    [NeighborContactRequest] = []

    @State
    private var sendingNeighborIds:
    Set<Int> = []

    @State
    private var contactRequestError = ""


    private let apiBaseURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com" +
    "/server/resident_function/api/residents"


    // MARK: - Display Area

    private var residentAreaName:
    String {

        let neighborhood =
        neighborhoodName
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        )

        if !neighborhood.isEmpty {
            return neighborhood
        }

        let area =
        displayAreaName
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        )

        if !area.isEmpty {
            return area
        }

        return "Your Community"
    }


    // MARK: - Services

    private var serviceOptions:
    [String] {

        var services:
        [String] = []

        for vendor in vendors {

            if let categories =
            vendor.categories {

                services.append(
                    contentsOf:
                    categories
                )
            }

            if let category =
            vendor.category,
            !category.isEmpty {

                services.append(
                    category
                )
            }
        }


        var unique:
        [String: String] = [:]

        for service in services {

            let clean =
            service
            .trimmingCharacters(
                in:
                .whitespacesAndNewlines
            )

            guard !clean.isEmpty else {
                continue
            }

            let key =
            canonicalService(
                clean
            )

            if unique[key] == nil {
                unique[key] =
                displayServiceName(
                    clean
                )
            }
        }


        return unique
        .values
        .sorted {
            $0.localizedCaseInsensitiveCompare(
                $1
            ) == .orderedAscending
        }
    }


    private var filteredVendors:
    [Vendor] {

        guard
        !selectedService.isEmpty
        else {
            return []
        }

        let selectedKey =
        canonicalService(
            selectedService
        )


        return vendors.filter {
            vendor in

            vendorServices(
                vendor
            )
            .contains {
                canonicalService(
                    $0
                ) ==
                selectedKey
            }
        }
    }


    // MARK: - Body

    var body: some View {

        NeonBackground {

            ScrollView {

                VStack(
                    spacing: 20
                ) {

                    residentCard

                    Text(
                        "Vendor Directory"
                    )
                    .font(
                        .largeTitle.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    serviceSelectionCard


                    if isLoading {

                        ProgressView(
                            "Loading vendors..."
                        )
                        .tint(.cyan)
                        .foregroundStyle(
                            .white
                        )
                        .padding(
                            .vertical,
                            30
                        )

                    } else if
                    !errorMessage.isEmpty {

                        Text(
                            errorMessage
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .red
                        )

                    } else if
                    selectedService.isEmpty {

                        chooseServiceMessage

                    } else if
                    filteredVendors.isEmpty {

                        noVendorsMessage

                    } else {

                        LazyVStack(
                            spacing: 18
                        ) {

                            ForEach(
                                filteredVendors
                            ) {
                                vendor in

                                vendorCard(
                                    vendor
                                )
                            }
                        }
                    }


                    Spacer(
                        minLength:
                        100
                    )
                }
                .padding()
            }
            .scrollIndicators(
                .hidden
            )
        }
        .task(
            id:
            residentId
        ) {

            await loadDirectory()
        }
        .sheet(
            item:
            $selectedNeighborVendor
        ) {
            vendor in

            neighborReferencesSheet(
                vendor
            )
            .presentationDetents(
                [
                    .medium,
                    .large
                ]
            )
        }
    }


    // MARK: - Resident Card

    private var residentCard:
    some View {

        VStack(
            spacing: 8
        ) {

            Text(
                "\(firstName) \(lastName)"
            )
            .font(
                .title.bold()
            )
            .foregroundStyle(
                .white
            )


            HStack(
                spacing: 7
            ) {

                Image(
                    systemName:
                    "house.fill"
                )

                Text(
                    residentAreaName
                )
            }
            .font(
                .headline
            )
            .foregroundStyle(
                .cyan
            )
        }
        .padding()
        .frame(
            maxWidth:
            .infinity
        )
        .background(
            .white.opacity(
                0.08
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                22
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius:
                22
            )
            .stroke(
                .cyan.opacity(
                    0.30
                ),
                lineWidth:
                1
            )
        }
        .shadow(
            color:
            .cyan.opacity(
                0.20
            ),
            radius:
            10
        )
    }


    // MARK: - Service Picker

    private var serviceSelectionCard:
    some View {

        VStack(
            alignment:
            .leading,
            spacing:
            12
        ) {

            Text(
                "Choose a Service"
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .cyan
            )


            Menu {

                ForEach(
                    serviceOptions,
                    id:
                    \.self
                ) {
                    service in

                    Button {

                        selectedService =
                        service

                    } label: {

                        if service ==
                        selectedService {

                            Label(
                                service,
                                systemImage:
                                "checkmark"
                            )

                        } else {

                            Text(
                                service
                            )
                        }
                    }
                }

            } label: {

                HStack {

                    Image(
                        systemName:
                        "wrench.and.screwdriver.fill"
                    )

                    Text(
                        selectedService.isEmpty
                        ? "Select Service Category"
                        : selectedService
                    )
                    .font(
                        .headline
                    )

                    Spacer()

                    Image(
                        systemName:
                        "chevron.down"
                    )
                }
                .foregroundStyle(
                    selectedService.isEmpty
                    ? .white.opacity(
                        0.72
                    )
                    : .white
                )
                .padding()
                .background(
                    .black.opacity(
                        0.24
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                        15
                    )
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius:
                        15
                    )
                    .stroke(
                        .cyan.opacity(
                            0.45
                        ),
                        lineWidth:
                        1
                    )
                }
            }
        }
        .padding(
            18
        )
        .frame(
            maxWidth:
            .infinity,
            alignment:
            .leading
        )
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(
                        0.10
                    ),
                    .purple.opacity(
                        0.18
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
                24
            )
        )
    }


    private var chooseServiceMessage:
    some View {

        VStack(
            spacing:
            12
        ) {

            Image(
                systemName:
                "magnifyingglass.circle.fill"
            )
            .font(
                .system(
                    size:
                    45
                )
            )
            .foregroundStyle(
                .cyan
            )


            Text(
                "Choose a service category"
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .white
            )


            Text(
                "We'll show local companies that provide the service you need."
            )
            .font(
                .subheadline
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
            28
        )
    }


    private var noVendorsMessage:
    some View {

        VStack(
            spacing:
            10
        ) {

            Image(
                systemName:
                "building.2.crop.circle"
            )
            .font(
                .system(
                    size:
                    42
                )
            )
            .foregroundStyle(
                .orange
            )


            Text(
                "No vendors found"
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .white
            )


            Text(
                "We don't have a vendor listed for \(selectedService) in your area yet."
            )
            .font(
                .subheadline
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
            24
        )
    }


    // MARK: - Vendor Card

    private func vendorCard(
    _ vendor:
    Vendor
    ) -> some View {

        VStack(
            alignment:
            .leading,
            spacing:
            16
        ) {

            HStack(
                alignment:
                .top,
                spacing:
                14
            ) {

                vendorLogo(
                    vendor
                )


                VStack(
                    alignment:
                    .leading,
                    spacing:
                    5
                ) {

                    Text(
                        vendor.company_name
                    )
                    .font(
                        .title3.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    if let category =
                    vendor.category,
                    !category.isEmpty {

                        Text(
                            displayServiceName(
                                category
                            )
                        )
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }


                    if let distance =
                    closestNeighborDistance(
                        vendor
                    ) {

                        Label(
                            "\(formatDistance(distance)) miles away",
                            systemImage:
                            "mappin.circle.fill"
                        )
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            .orange
                        )


                        Text(
                            "Closest neighbor who used this company"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.55
                            )
                        )
                    }
                }


                Spacer()
            }


            if let description =
            vendor.description,
            !description.isEmpty {

                Text(
                    description
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.72
                    )
                )
                .lineSpacing(
                    3
                )
            }


            neighborReferenceButton(
                vendor
            )


            NavigationLink {

                ContactView(
                    preselectedVendorId:
                    vendor.id,

                    preselectedService:
                    primaryService(
                        vendor
                    )
                )

            } label: {

                HStack(
                    spacing:
                    8
                ) {

                    Image(
                        systemName:
                        "calendar.badge.plus"
                    )

                    Text(
                        "Request Service"
                    )
                    .font(
                        .headline.bold()
                    )
                }
                .foregroundStyle(
                    .white
                )
                .frame(
                    maxWidth:
                    .infinity
                )
                .padding(
                    .vertical,
                    13
                )
                .background(
                    LinearGradient(
                        colors: [
                            .cyan,
                            .purple
                        ],
                        startPoint:
                        .leading,
                        endPoint:
                        .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                        14
                    )
                )
            }
            .buttonStyle(
                .plain
            )
        }
        .padding(
            18
        )
        .frame(
            maxWidth:
            .infinity,
            alignment:
            .leading
        )
        .background(
            LinearGradient(
                colors: [
                    .white.opacity(
                        0.08
                    ),
                    .purple.opacity(
                        0.12
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
                24
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius:
                24
            )
            .stroke(
                .cyan.opacity(
                    0.30
                ),
                lineWidth:
                1
            )
        }
    }


    // MARK: - Neighbor Reference Button

    @ViewBuilder
    private func neighborReferenceButton(
    _ vendor:
    Vendor
    ) -> some View {

        let count =
        vendor
        .signed_up_people?
        .count ??
        0


        if count > 0 {

            Button {

                contactRequestError =
                ""

                selectedNeighborVendor =
                vendor

            } label: {

                HStack(
                    spacing:
                    10
                ) {

                    Image(
                        systemName:
                        "star.fill"
                    )
                    .foregroundStyle(
                        .orange
                    )


                    Text(
                        count == 1
                        ? "1 neighbor uses this vendor"
                        : "\(count) neighbors use this vendor"
                    )
                    .font(
                        .subheadline.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    Spacer()


                    Image(
                        systemName:
                        "chevron.right"
                    )
                    .foregroundStyle(
                        .cyan
                    )
                }
                .padding(
                    14
                )
                .background(
                    .black.opacity(
                        0.22
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                        14
                    )
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius:
                        14
                    )
                    .stroke(
                        .orange.opacity(
                            0.35
                        ),
                        lineWidth:
                        1
                    )
                }
            }
            .buttonStyle(
                .plain
            )

        } else {

            Label(
                "No neighbor references yet",
                systemImage:
                "person.2"
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .white.opacity(
                    0.55
                )
            )
        }
    }


    // MARK: - Neighbor References Sheet

    private func neighborReferencesSheet(
    _ vendor:
    Vendor
    ) -> some View {

        NavigationStack {

            NeonBackground {

                ScrollView {

                    VStack(
                        alignment:
                        .leading,
                        spacing:
                        18
                    ) {

                        VStack(
                            alignment:
                            .leading,
                            spacing:
                            5
                        ) {

                            Text(
                                "Neighbors Who Used"
                            )
                            .font(
                                .headline
                            )
                            .foregroundStyle(
                                .cyan
                            )


                            Text(
                                vendor.company_name
                            )
                            .font(
                                .largeTitle.bold()
                            )
                            .foregroundStyle(
                                .white
                            )


                            Text(
                                "Ask a neighbor about their experience before choosing a company."
                            )
                            .font(
                                .subheadline
                            )
                            .foregroundStyle(
                                .white.opacity(
                                    0.68
                                )
                            )
                        }


                        if
                        !contactRequestError
                        .isEmpty {

                            Text(
                                contactRequestError
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .orange
                            )
                        }


                        ForEach(
                            sortedNeighbors(
                                vendor
                            )
                        ) {
                            person in

                            neighborReferenceCard(
                                person:
                                person,
                                vendor:
                                vendor
                            )
                        }
                    }
                    .padding()
                }
            }
            .toolbar {

                ToolbarItem(
                    placement:
                    .topBarTrailing
                ) {

                    Button(
                        "Done"
                    ) {

                        selectedNeighborVendor =
                        nil
                    }
                }
            }
        }
    }


    // MARK: - Neighbor Card

    private func neighborReferenceCard(
    person:
    VendorSignupPerson,
    vendor:
    Vendor
    ) -> some View {

        let existingRequest =
        outgoingRequest(
            personId:
            person.id,
            vendorId:
            vendor.id
        )


        return VStack(
            alignment:
            .leading,
            spacing:
            12
        ) {

            HStack(
                alignment:
                .top,
                spacing:
                12
            ) {

                Image(
                    systemName:
                    "person.crop.circle.fill"
                )
                .font(
                    .system(
                        size:
                        38
                    )
                )
                .foregroundStyle(
                    .cyan
                )


                VStack(
                    alignment:
                    .leading,
                    spacing:
                    5
                ) {

                    Text(
                        person.first_name?
                        .trimmingCharacters(
                            in:
                            .whitespacesAndNewlines
                        )
                        .isEmpty == false
                        ? person.first_name!
                        : "Neighbor"
                    )
                    .font(
                        .headline.bold()
                    )
                    .foregroundStyle(
                        .white
                    )


                    if let address =
                    cleanAddress(
                        person.address
                    ) {

                        Text(
                            address
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


                    if let distance =
                    person.distance_miles {

                        Label(
                            "\(formatDistance(distance)) miles away",
                            systemImage:
                            "mappin.circle.fill"
                        )
                        .font(
                            .caption.bold()
                        )
                        .foregroundStyle(
                            .orange
                        )
                    }
                }


                Spacer()
            }


            if let photoString =
            person.finished_photo_url,
            let photoURL =
            URL(
                string:
                photoString
            ) {

                AsyncImage(
                    url:
                    photoURL
                ) {
                    phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                        .tint(
                            .cyan
                        )
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .frame(
                            height:
                            150
                        )


                    case .success(
                    let image
                    ):

                        image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .frame(
                            height:
                            150
                        )
                        .clipped()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                14
                            )
                        )


                    default:

                        EmptyView()
                    }
                }
            }


            neighborContactAction(
                person:
                person,
                vendor:
                vendor,
                request:
                existingRequest
            )
        }
        .padding(
            16
        )
        .background(
            .white.opacity(
                0.08
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                20
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius:
                20
            )
            .stroke(
                .cyan.opacity(
                    0.25
                ),
                lineWidth:
                1
            )
        }
    }


    // MARK: - Contact Action

    @ViewBuilder
    private func neighborContactAction(
    person:
    VendorSignupPerson,
    vendor:
    Vendor,
    request:
    NeighborContactRequest?
    ) -> some View {

        let status =
        request?
        .status?
        .lowercased()


        if status ==
        "accepted" {

            VStack(
                alignment:
                .leading,
                spacing:
                9
            ) {

                Label(
                    "Contact request accepted",
                    systemImage:
                    "checkmark.circle.fill"
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    .green
                )


                if let phone =
                request?
                .target_phone,
                !phone.isEmpty {

                    Link(
                        destination:
                        URL(
                            string:
                            "tel:\(phone)"
                        )!
                    ) {

                        HStack {

                            Image(
                                systemName:
                                "phone.fill"
                            )

                            Text(
                                formatPhoneNumber(
                                    phone
                                )
                            )
                            .font(
                                .headline.bold()
                            )
                        }
                        .foregroundStyle(
                            .white
                        )
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .padding(
                            .vertical,
                            12
                        )
                        .background(
                            .green.opacity(
                                0.70
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                13
                            )
                        )
                    }
                }
            }

        } else if status ==
        "pending" {

            Label(
                "Contact request pending",
                systemImage:
                "clock.fill"
            )
            .font(
                .subheadline.bold()
            )
            .foregroundStyle(
                .orange
            )
            .frame(
                maxWidth:
                .infinity
            )
            .padding(
                .vertical,
                12
            )
            .background(
                .orange.opacity(
                    0.12
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                    13
                )
            )

        } else {

            Button {

                Task {

                    await sendNeighborContactRequest(
                        person:
                        person,
                        vendor:
                        vendor
                    )
                }

            } label: {

                HStack(
                    spacing:
                    8
                ) {

                    if
                    sendingNeighborIds
                    .contains(
                        person.id
                    ) {

                        ProgressView()
                        .tint(
                            .white
                        )

                    } else {

                        Image(
                            systemName:
                            "person.crop.circle.badge.plus"
                        )
                    }


                    Text(
                        status ==
                        "declined"
                        ? "Request Again"
                        : "Request to Contact"
                    )
                    .font(
                        .headline.bold()
                    )
                }
                .foregroundStyle(
                    .white
                )
                .frame(
                    maxWidth:
                    .infinity
                )
                .padding(
                    .vertical,
                    12
                )
                .background(
                    LinearGradient(
                        colors: [
                            .orange,
                            .purple
                        ],
                        startPoint:
                        .leading,
                        endPoint:
                        .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                        13
                    )
                )
            }
            .buttonStyle(
                .plain
            )
            .disabled(
                sendingNeighborIds
                .contains(
                    person.id
                )
            )
        }
    }


    // MARK: - Logo

    @ViewBuilder
    private func vendorLogo(
    _ vendor:
    Vendor
    ) -> some View {

        if let logo =
        vendor.logo_url,
        !logo.isEmpty,
        let url =
        URL(
            string:
            logo
        ) {

            AsyncImage(
                url:
                url
            ) {
                phase in

                switch phase {

                case .empty:

                    ProgressView()
                    .tint(
                        .cyan
                    )


                case .success(
                let image
                ):

                    image
                    .resizable()
                    .scaledToFit()


                default:

                    vendorLogoPlaceholder
                }
            }
            .frame(
                width:
                72,
                height:
                72
            )
            .padding(
                6
            )
            .background(
                .white
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                    15
                )
            )

        } else {

            vendorLogoPlaceholder
        }
    }


    private var vendorLogoPlaceholder:
    some View {

        Image(
            systemName:
            "building.2.fill"
        )
        .font(
            .system(
                size:
                28
            )
        )
        .foregroundStyle(
            .cyan
        )
        .frame(
            width:
            72,
            height:
            72
        )
        .background(
            .white.opacity(
                0.08
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                15
            )
        )
    }


    // MARK: - Load Directory

    @MainActor
    private func loadDirectory()
    async {

        await loadVendors()

        await loadNeighborContactRequests()
    }


    @MainActor
    private func loadVendors()
    async {

        guard residentId > 0 else {

            errorMessage =
            "Resident profile not found."

            isLoading =
            false

            return
        }


        isLoading =
        true

        errorMessage =
        ""


        guard let url =
        URL(
            string:
            "\(apiBaseURL)/vendors/\(residentId)"
        )
        else {

            errorMessage =
            "Invalid vendor directory URL."

            isLoading =
            false

            return
        }


        do {

            let (
            data,
            response
            ) =
            try await URLSession
            .shared
            .data(
                from:
                url
            )


            guard
            let httpResponse =
            response
            as?
            HTTPURLResponse,
            (200...299)
            .contains(
                httpResponse
                .statusCode
            )
            else {

                errorMessage =
                serverErrorMessage(
                    data
                ) ??
                "Could not load vendors."

                isLoading =
                false

                return
            }


            let decoded =
            try JSONDecoder()
            .decode(
                VendorResponse.self,
                from:
                data
            )


            if decoded.success ==
            true {

                vendors =
                decoded.vendors ??
                []

            } else {

                errorMessage =
                decoded.error ??
                "Could not load vendors."
            }

        } catch {

            errorMessage =
            error.localizedDescription
        }


        isLoading =
        false
    }


    // MARK: - Load Contact Requests

    @MainActor
    private func loadNeighborContactRequests()
    async {

        guard residentId > 0 else {
            return
        }


        guard let url =
        URL(
            string:
            "\(apiBaseURL)/\(residentId)/neighbor-contact-requests"
        )
        else {
            return
        }


        do {

            let (
            data,
            response
            ) =
            try await URLSession
            .shared
            .data(
                from:
                url
            )


            guard
            let httpResponse =
            response
            as?
            HTTPURLResponse,
            (200...299)
            .contains(
                httpResponse
                .statusCode
            )
            else {
                return
            }


            let decoded =
            try JSONDecoder()
            .decode(
                NeighborContactRequestsResponse.self,
                from:
                data
            )


            outgoingContactRequests =
            decoded.outgoing ??
            []

        } catch {

            print(
                "loadNeighborContactRequests:",
                error
            )
        }
    }


    // MARK: - Send Contact Request

    @MainActor
    private func sendNeighborContactRequest(
    person:
    VendorSignupPerson,
    vendor:
    Vendor
    ) async {

        guard residentId > 0 else {
            return
        }


        sendingNeighborIds.insert(
            person.id
        )

        contactRequestError =
        ""


        defer {

            sendingNeighborIds.remove(
                person.id
            )
        }


        guard let url =
        URL(
            string:
            "\(apiBaseURL)/\(residentId)/neighbor-contact-requests"
        )
        else {

            contactRequestError =
            "Could not create contact request."

            return
        }


        let neighborName =
        person.first_name?
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        ) ??
        "your neighbor"


        let payload:
        [String: Any] = [

            "target_resident_id":
            person.id,

            "vendor_id":
            vendor.id,

            "message":
            "I'd like to ask about your experience with \(vendor.company_name)."
        ]


        do {

            var request =
            URLRequest(
                url:
                url
            )

            request.httpMethod =
            "POST"

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

            request.httpBody =
            try JSONSerialization
            .data(
                withJSONObject:
                payload
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


            guard
            let httpResponse =
            response
            as?
            HTTPURLResponse
            else {

                contactRequestError =
                "Invalid response."

                return
            }


            let decoded =
            try?
            JSONDecoder()
            .decode(
                NeighborContactCreateResponse.self,
                from:
                data
            )


            if (200...299)
            .contains(
                httpResponse
                .statusCode
            ) {

                if let newRequest =
                decoded?
                .request {

                    outgoingContactRequests
                    .insert(
                        newRequest,
                        at:
                        0
                    )

                } else {

                    await loadNeighborContactRequests()
                }


                contactRequestError =
                "Request sent to \(neighborName)."

                return
            }


            /*
             * If the server says a pending request
             * already exists, refresh our state so
             * the row switches to "pending".
             */
            if httpResponse.statusCode ==
            409 {

                await loadNeighborContactRequests()
            }


            contactRequestError =
            decoded?
            .error ??
            "Could not send contact request."

        } catch {

            contactRequestError =
            error.localizedDescription
        }
    }


    // MARK: - Helpers

    private func outgoingRequest(
    personId:
    Int,
    vendorId:
    Int
    ) -> NeighborContactRequest? {

        outgoingContactRequests
        .first {
            request in

            request.target_resident_id ==
            personId &&
            request.vendor_id ==
            vendorId
        }
    }


    private func sortedNeighbors(
    _ vendor:
    Vendor
    ) -> [VendorSignupPerson] {

        (
        vendor.signed_up_people ??
        []
        )
        .sorted {

            let left =
            $0.distance_miles ??
            Double.greatestFiniteMagnitude

            let right =
            $1.distance_miles ??
            Double.greatestFiniteMagnitude

            return left <
            right
        }
    }


    private func closestNeighborDistance(
    _ vendor:
    Vendor
    ) -> Double? {

        vendor
        .signed_up_people?
        .compactMap {
            $0.distance_miles
        }
        .min()
    }


    private func vendorServices(
    _ vendor:
    Vendor
    ) -> [String] {

        var values:
        [String] = []

        if let categories =
        vendor.categories {

            values.append(
                contentsOf:
                categories
            )
        }

        if let category =
        vendor.category,
        !category.isEmpty {

            values.append(
                category
            )
        }

        return values
    }


    private func primaryService(
    _ vendor:
    Vendor
    ) -> String {

        if !selectedService.isEmpty {
            return selectedService
        }

        if let first =
        vendor.categories?
        .first {

            return first
        }

        return vendor.category ??
        "General Contractor"
    }


    private func canonicalService(
    _ value:
    String
    ) -> String {

        value
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        )
        .lowercased()
        .replacingOccurrences(
            of:
            "_",
            with:
            " "
        )
        .replacingOccurrences(
            of:
            "-",
            with:
            " "
        )
        .replacingOccurrences(
            of:
            "  ",
            with:
            " "
        )
    }


    private func displayServiceName(
    _ value:
    String
    ) -> String {

        value
        .replacingOccurrences(
            of:
            "_",
            with:
            " "
        )
        .trimmingCharacters(
            in:
            .whitespacesAndNewlines
        )
        .capitalized
    }


    private func formatDistance(
    _ value:
    Double
    ) -> String {

        String(
            format:
            "%.1f",
            value
        )
    }


    private func cleanAddress(
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


    private func formatPhoneNumber(
    _ value:
    String
    ) -> String {

        var digits =
        value.filter {
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

            return value
        }


        let area =
        digits.prefix(
            3
        )

        let middle =
        digits.dropFirst(
            3
        )
        .prefix(
            3
        )

        let last =
        digits.suffix(
            4
        )


        return
        "(\(area)) \(middle)-\(last)"
    }


    private func serverErrorMessage(
    _ data:
    Data
    ) -> String? {

        guard
        let object =
        try?
        JSONSerialization
        .jsonObject(
            with:
            data
        )
        as?
        [String: Any]
        else {

            return nil
        }


        return
        object["error"]
        as?
        String
    }
}