import SwiftUI
import MapKit
import UIKit

struct StreetFairResidentView: View {

    // MARK: - Resident State
    @State
    private var lookAroundScene: MKLookAroundScene?

    @State
    private var isLoadingLookAround = false

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentFirstName")
    private var firstName = ""

    @AppStorage("residentLastName")
    private var lastName = ""

    @AppStorage("residentPhone")
    private var phone = ""

    @AppStorage("residentAddress")
    private var address = ""

    @AppStorage("residentNeighborhoodName")
    private var neighborhoodName = ""

    @AppStorage("residentDisplayAreaName")
    private var displayAreaName = ""

    @AppStorage("residentIsSignedUp")
    private var residentIsSignedUp = false

    @AppStorage("residentHomeMode")
    private var residentHomeMode = "standard"


    // MARK: - Support Mode

    @AppStorage("supportResidentMode")
    private var supportResidentMode = false

    @AppStorage("supportSignupMode")
    private var supportSignupMode = false

    @AppStorage("vendorId")
    private var supportVendorId = 0

    @AppStorage("vendorCompanyName")
    private var supportVendorCompanyName = ""

    @State private var showingSupportResidentSwitcher = false

    @State private var isLeavingSupportMode = false

    @State private var supportModeError = ""


    // MARK: - Sheets

    @State private var showingAccountSettings = false


    // MARK: - Street Fair Services

    private let services: [StreetFairService] = [

        StreetFairService(
            title: "General Contracting",
            subtitle: "Repairs, remodeling & projects",
            icon: "hammer.fill"
        ),

        StreetFairService(
            title: "HVAC",
            subtitle: "Heating & air conditioning",
            icon: "thermometer.medium"
        ),

        StreetFairService(
            title: "Plumbing",
            subtitle: "Leaks, fixtures & repairs",
            icon: "drop.fill"
        ),

        StreetFairService(
            title: "Handyman / Fix-It",
            subtitle: "Everyday household repairs",
            icon: "wrench.and.screwdriver.fill"
        ),

        StreetFairService(
            title: "Electrical",
            subtitle: "Home electrical service",
            icon: "bolt.fill"
        ),

        StreetFairService(
            title: "Landscaping",
            subtitle: "Landscape & outdoor projects",
            icon: "leaf.fill"
        ),

        StreetFairService(
            title: "Fence Staining",
            subtitle: "Protect & refresh your fence",
            icon: "paintbrush.fill"
        ),

        StreetFairService(
            title: "Windows / Doors / Siding",
            subtitle: "Exterior home improvements",
            icon: "house.fill"
        )
    ]
    private var cleanAddress: String {

        address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }


    private var residentDisplayName: String {

        let name =
        "\(firstName) \(lastName)"
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return name.isEmpty
        ? "Your Home"
        : name
    }

    // MARK: - Display Values

    private var residentName: String {

        let name = "\(firstName) \(lastName)"
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return name.isEmpty
        ? "Resident"
        : name
    }


    private var neighborhoodDisplayName: String {

        let cleanNeighborhood =
        neighborhoodName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !cleanNeighborhood.isEmpty {
            return cleanNeighborhood
        }

        let cleanArea =
        displayAreaName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !cleanArea.isEmpty {
            return cleanArea
        }

        return "Your Neighborhood"
    }


    private var isGlenEagles: Bool {

        neighborhoodDisplayName
        .lowercased()
        .contains("glen eagles")
    }


    private var inviteCode: String {

        if isGlenEagles {
            return "GLENEAGLES26"
        }

        return "STREET FAIR"
    }
    // MARK: - Resident Home / Look Around

    @ViewBuilder
    private var streetFairResidentHomeCard: some View {

        if let lookAroundScene {

            streetFairLookAroundCard(
                scene: lookAroundScene
            )

        } else if isLoadingLookAround {

            VStack(spacing: 12) {

                ProgressView()
                .tint(.cyan)
                .scaleEffect(1.1)

                Text("Loading your home...")
                .font(.subheadline.bold())
                .foregroundStyle(
                    .white.opacity(0.80)
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(
                .white.opacity(0.06)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )

        } else {

            ZStack(
                alignment: .bottomLeading
            ) {

                Image(
                    "clubhouse_links_home_fallback"
                )
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 230)
                .clipped()


                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.08),
                        .black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )


                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Label(
                        "Clubhouse Links",
                        systemImage:
                        "house.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)


                    Text(residentDisplayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)


                    if !cleanAddress.isEmpty {

                        Text(cleanAddress)
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(0.86)
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                    }


                    Text(
                        "Apple Look Around is not available for this address."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.60)
                    )
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(
                .white.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 24
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            .cyan,
                            .purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            }
        }
    }


    private func streetFairLookAroundCard(
    scene: MKLookAroundScene
    ) -> some View {

        ZStack(
            alignment: .bottomLeading
        ) {

            StreetFairLookAroundControllerView(
                scene: scene
            )
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .allowsHitTesting(false)


            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.08),
                    .black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )


            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Label(
                    "Apple Look Around",
                    systemImage:
                    "binoculars.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.cyan)


                Text(residentDisplayName)
                .font(.title2.bold())
                .foregroundStyle(.white)


                if !phone.isEmpty {

                    Text(phone)
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.76)
                    )
                }


                Text(cleanAddress)
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.86)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .background(
            .white.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 24
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        }
        .shadow(
            color: .cyan.opacity(0.25),
            radius: 12
        )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            NeonBackground {

                ScrollView {

                    VStack(spacing: 20) {

                        if supportResidentMode {
                            supportModeBanner
                        }

                        residentHeader

                        streetFairHero

                        eventExplanationCard

                        howItWorksCard

                        servicesSection

                        mainActionCard

                        inviteCodeCard

                        regularPortalCard

                        Spacer(
                            minLength: 120
                        )
                    }
                    .padding()
                }
                .scrollIndicators(
                    .hidden
                )
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
        }
        .sheet(
            isPresented:
            $showingAccountSettings
        ) {

            AccountSettingsView()
        }
        .sheet(
            isPresented:
            $showingSupportResidentSwitcher
        ) {

            SupportResidentPickerView()
        }
        .onAppear {

            loadResidentLookAround()
        }
        .onChange(of: residentId) { _ in

            loadResidentLookAround()
        }
        .onChange(of: address) { _ in

            loadResidentLookAround()
        }
    }


    // MARK: - Resident Header

    private var residentHeader: some View {

        VStack(spacing: 12) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "WELCOME, \(firstName.uppercased())"
                    )
                    .font(.caption.bold())
                    .tracking(1.1)
                    .foregroundStyle(.cyan)

                    Text(
                        neighborhoodDisplayName
                    )
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                }

                Spacer()

                Button {

                    showingAccountSettings = true

                } label: {

                    ZStack {

                        Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .cyan.opacity(0.35),
                                    .purple.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: 54,
                            height: 54
                        )

                        Circle()
                        .stroke(
                            .cyan.opacity(0.8),
                            lineWidth: 1.5
                        )
                        .frame(
                            width: 54,
                            height: 54
                        )

                        Image(
                            systemName:
                            "slider.horizontal.3"
                        )
                        .font(
                            .system(
                                size: 21,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }

            Text(
                "Clubhouse Links Street Fair"
            )
            .font(.title2.bold())
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .orange,
                        .yellow,
                        .cyan
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }


    // MARK: - Hero

    private var streetFairHero: some View {

        VStack(spacing: 18) {

            streetFairResidentHomeCard

            VStack(spacing: 8) {

                Text(
                    "WE'RE COMING TO YOUR NEIGHBORHOOD"
                )
                .font(.caption.bold())
                .tracking(1.4)
                .foregroundStyle(.orange)

                Text(
                    "Last Week of September"
                )
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(
                    .center
                )

                Text(
                    neighborhoodDisplayName
                )
                .font(.title2.bold())
                .foregroundStyle(.cyan)
            }

            Text(
                "Clubhouse Links is bringing trusted local home-service professionals directly into \(neighborhoodDisplayName) for a full week of quotes, consultations, and scheduled work."
            )
            .font(.body.weight(.medium))
            .foregroundStyle(
                .white.opacity(0.82)
            )
            .multilineTextAlignment(
                .center
            )
            .lineSpacing(4)
        }
        .padding(24)
        .frame(
            maxWidth: .infinity
        )
        .background(
            LinearGradient(
                colors: [
                    .orange.opacity(0.17),
                    .purple.opacity(0.24),
                    .black.opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 30
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .orange.opacity(0.9),
                        .purple.opacity(0.7),
                        .cyan.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .shadow(
            color:
            .orange.opacity(0.20),
            radius: 14
        )
    }


    // MARK: - What Is It?

    private var eventExplanationCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Label(
                "What is the Street Fair?",
                systemImage:
                "sparkles"
            )
            .font(.title2.bold())
            .foregroundStyle(.white)

            Text(
                "Instead of calling multiple contractors and waiting for appointments across different weeks, participating service professionals will already be working in your neighborhood."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.78)
            )
            .lineSpacing(4)

            Divider()
            .overlay(
                .white.opacity(0.12)
            )

            Text(
                "Residents can request a service through Clubhouse Links, get connected with the appropriate local professional, and schedule a quote or work while the Street Fair is happening."
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                .cyan.opacity(0.95)
            )
            .lineSpacing(4)
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .white.opacity(0.07)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24
            )
            .stroke(
                .cyan.opacity(0.30),
                lineWidth: 1
            )
        )
    }


    // MARK: - How It Works

    private var howItWorksCard: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("How It Works")
            .font(.title2.bold())
            .foregroundStyle(.white)

            streetFairStep(
                number: "1",
                title: "Tell us what you need",
                text:
                "Choose the home service or project you would like help with."
            )

            streetFairStep(
                number: "2",
                title: "Get connected",
                text:
                "Clubhouse Links connects you with a participating professional serving the Street Fair."
            )

            streetFairStep(
                number: "3",
                title: "Schedule during Street Fair week",
                text:
                "Arrange a quote, consultation, or available work while professionals are already in the neighborhood."
            )
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.11),
                    .purple.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }


    private func streetFairStep(
    number: String,
    title: String,
    text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            ZStack {

                Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .orange,
                            .purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: 38,
                    height: 38
                )

                Text(number)
                .font(.headline.bold())
                .foregroundStyle(.white)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)

                Text(text)
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.70)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }


    // MARK: - Services

    private var servicesSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Street Fair Services"
            )
            .font(.title2.bold())
            .foregroundStyle(.white)

            Text(
                "Request help in any of these participating home-service categories."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.68)
            )

            LazyVGrid(
                columns: [
                    GridItem(
                        .flexible(),
                        spacing: 12
                    ),
                    GridItem(
                        .flexible(),
                        spacing: 12
                    )
                ],
                spacing: 12
            ) {

                ForEach(
                    services
                ) { service in

                    serviceCard(
                        service
                    )
                }
            }
        }
    }


    private func serviceCard(
    _ service: StreetFairService
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 9
        ) {

            Image(
                systemName:
                service.icon
            )
            .font(.title2)
            .foregroundStyle(.cyan)

            Text(service.title)
            .font(.headline.bold())
            .foregroundStyle(.white)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Text(service.subtitle)
            .font(.caption)
            .foregroundStyle(
                .white.opacity(0.62)
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Spacer(
                minLength: 2
            )
        }
        .padding(15)
        .frame(
            maxWidth: .infinity,
            minHeight: 135,
            alignment: .topLeading
        )
        .background(
            LinearGradient(
                colors: [
                    .white.opacity(0.08),
                    .purple.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                .cyan.opacity(0.25),
                lineWidth: 1
            )
        )
    }


    // MARK: - Main Action

    private var mainActionCard: some View {

        VStack(spacing: 14) {

            Image(
                systemName:
                "checkmark.circle.fill"
            )
            .font(
                .system(size: 46)
            )
            .foregroundStyle(.green)

            Text(
                "Ready to Start a Project?"
            )
            .font(.title2.bold())
            .foregroundStyle(.white)

            Text(
                "Browse trusted professionals participating in Clubhouse Links and find the right service for your home."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(
                .center
            )

            NavigationLink {
                StreetFairVendorDirectoryView(
                    residentId: residentId
                )
            } label: {

                HStack {

                    Image(
                        systemName:
                        "person.3.fill"
                    )

                    Text(
                        "View Contractors"
                    )
                    .font(.headline.bold())

                    Spacer()

                    Image(
                        systemName:
                        "chevron.right"
                    )
                }
                .padding()
                .frame(
                    maxWidth: .infinity
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
                        cornerRadius: 18
                    )
                )
                .shadow(
                    color:
                    .cyan.opacity(0.35),
                    radius: 10
                )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(
            maxWidth: .infinity
        )
        .background(
            .white.opacity(0.07)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26
            )
        )
    }


    // MARK: - Invite Code

    private var inviteCodeCard: some View {

        VStack(spacing: 8) {

            Text(
                "YOUR NEIGHBORHOOD ACCESS CODE"
            )
            .font(.caption.bold())
            .tracking(1.1)
            .foregroundStyle(
                .white.opacity(0.58)
            )

            Text(inviteCode)
            .font(
                .system(
                    size: 28,
                    weight: .heavy,
                    design: .rounded
                )
            )
            .foregroundStyle(.yellow)

            Text(
                "You're registered for the \(neighborhoodDisplayName) Street Fair experience."
            )
            .font(.caption)
            .foregroundStyle(
                .white.opacity(0.66)
            )
            .multilineTextAlignment(
                .center
            )
        }
        .padding(18)
        .frame(
            maxWidth: .infinity
        )
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
                .yellow.opacity(0.30),
                lineWidth: 1
            )
        )
    }


    // MARK: - Normal Resident Portal

    private var regularPortalCard: some View {

        VStack(spacing: 12) {

            Text(
                "Your Full Resident Portal"
            )
            .font(.headline.bold())
            .foregroundStyle(.white)

            Text(
                "You still have access to your regular Clubhouse Links profile, completed projects, neighborhood contractors, and account tools."
            )
            .font(.caption)
            .foregroundStyle(
                .white.opacity(0.64)
            )
            .multilineTextAlignment(
                .center
            )

            NavigationLink {

                ResidentProfileView()

            } label: {

                Label(
                    "Open Resident Portal",
                    systemImage:
                    "house.circle.fill"
                )
                .font(.headline.bold())
                .foregroundStyle(.cyan)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(
            maxWidth: .infinity
        )
        .background(
            .white.opacity(0.05)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }


    // MARK: - Support Mode Banner

    private var supportModeBanner: some View {

        VStack(spacing: 12) {

            HStack(spacing: 8) {

                Image(
                    systemName:
                    "wrench.and.screwdriver.fill"
                )

                Text("SUPPORT MODE")
                .font(.caption.bold())
                .tracking(1.2)

                Spacer()

                Circle()
                .fill(.green)
                .frame(
                    width: 8,
                    height: 8
                )
            }
            .foregroundStyle(.orange)

            Text(
                "Viewing \(residentName)"
            )
            .font(.headline.bold())
            .foregroundStyle(.white)

            if !supportVendorCompanyName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {

                Text(
                    "Supporting as \(supportVendorCompanyName)"
                )
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }

            HStack(spacing: 10) {

                Button {

                    showingSupportResidentSwitcher = true

                } label: {

                    Label(
                        "Switch Resident",
                        systemImage:
                        "person.2.fill"
                    )
                    .font(.caption.bold())
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        12
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    .purple.opacity(0.85)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )


                Button {

                    Task {
                        await returnToVendor()
                    }

                } label: {

                    if isLeavingSupportMode {

                        ProgressView()
                        .tint(.white)
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .padding(
                            .vertical,
                            12
                        )

                    } else {

                        Label(
                            "Return to Aspen",
                            systemImage:
                            "arrow.uturn.backward.circle.fill"
                        )
                        .font(.caption.bold())
                        .frame(
                            maxWidth:
                            .infinity
                        )
                        .padding(
                            .vertical,
                            12
                        )
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    .orange.opacity(0.90)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
                .disabled(
                    isLeavingSupportMode
                )
            }

            Button {

                Task {
                    await startNewSignupTest()
                }

            } label: {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                        "person.badge.plus"
                    )

                    Text(
                        "Test New Signup"
                    )
                    .font(.caption.bold())

                    Spacer()

                    Text("SMS / Twilio")
                    .font(.caption2)
                    .opacity(0.7)

                    Image(
                        systemName:
                        "chevron.right"
                    )
                    .font(.caption)
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    12
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [
                        .cyan.opacity(0.8),
                        .purple.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )

            if !supportModeError.isEmpty {

                Text(
                    supportModeError
                )
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(
                    .center
                )
            }
        }
        .padding()
        .background(
            .black.opacity(0.50)
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
                .orange.opacity(0.75),
                lineWidth: 1.5
            )
        )
    }
    // MARK: - Apple Look Around

    private func loadResidentLookAround() {

        let requestedResidentId =
        residentId

        let requestedAddress =
        cleanAddress

        lookAroundScene = nil
        isLoadingLookAround = false


        guard
        requestedResidentId > 0,
        !requestedAddress.isEmpty
        else {
            return
        }


        isLoadingLookAround = true


        Task {

            do {

                let searchRequest =
                MKLocalSearch.Request()

                searchRequest
                .naturalLanguageQuery =
                requestedAddress

                searchRequest.resultTypes =
                .address


                let search =
                MKLocalSearch(
                    request:
                    searchRequest
                )

                let searchResponse =
                try await search.start()


                guard let mapItem =
                searchResponse
                .mapItems
                .first
                else {

                    await MainActor.run {

                        guard
                        requestedResidentId ==
                        residentId,
                        requestedAddress ==
                        cleanAddress
                        else {
                            return
                        }

                        lookAroundScene = nil
                        isLoadingLookAround = false
                    }

                    return
                }


                let sceneRequest =
                MKLookAroundSceneRequest(
                    mapItem: mapItem
                )


                let scene =
                try await
                sceneRequest.scene


                await MainActor.run {

                    guard
                    requestedResidentId ==
                    residentId,
                    requestedAddress ==
                    cleanAddress
                    else {
                        return
                    }

                    lookAroundScene = scene
                    isLoadingLookAround = false
                }

            } catch {

                await MainActor.run {

                    guard
                    requestedResidentId ==
                    residentId,
                    requestedAddress ==
                    cleanAddress
                    else {
                        return
                    }

                    lookAroundScene = nil
                    isLoadingLookAround = false
                }

                print(
                    "[Street Fair Look Around]",
                    error.localizedDescription
                )
            }
        }
    }

    // MARK: - Return to Vendor

    @MainActor
    private func returnToVendor() async {

        guard supportResidentMode,
        supportVendorId > 0 else {
            return
        }

        isLeavingSupportMode = true
        supportModeError = ""

        defer {
            isLeavingSupportMode = false
        }

        do {

            try await
            SupportResidentAPI.shared
            .clearResident(
                vendorId:
                supportVendorId
            )

            clearResidentSupportState()

            supportResidentMode = false
            supportSignupMode = false

            VendorPushRegistration
            .syncStoredToken()

        } catch {

            supportModeError =
            error.localizedDescription
        }
    }


    // MARK: - Test New Signup

    @MainActor
    private func startNewSignupTest() async {

        guard supportVendorId > 0 else {

            supportModeError =
            "The support vendor account could not be found."

            return
        }

        supportModeError = ""

        do {

            try await
            SupportResidentAPI.shared
            .clearResident(
                vendorId:
                supportVendorId
            )

            clearResidentSupportState()

            supportResidentMode = false
            supportSignupMode = true

        } catch {

            supportModeError =
            error.localizedDescription
        }
    }


    // MARK: - Clear Temporary Resident State

    private func clearResidentSupportState() {

        residentId = 0
        residentIsSignedUp = false

        firstName = ""
        lastName = ""
        phone = ""
        address = ""
        neighborhoodName = ""
        displayAreaName = ""

        /*
         * Prevent the next support account from
         * accidentally inheriting the Street Fair UI.
         */
        residentHomeMode = "standard"

        UserDefaults.standard
        .removeObject(
            forKey:
            "residentNeighborhoodId"
        )
    }
}

private struct StreetFairLookAroundControllerView:
UIViewControllerRepresentable {

    let scene: MKLookAroundScene


    func makeUIViewController(
    context: Context
    ) -> MKLookAroundViewController {

        let controller =
        MKLookAroundViewController(
            scene: scene
        )

        controller.isNavigationEnabled =
        false

        controller.showsRoadLabels =
        false

        return controller
    }


    func updateUIViewController(
    _ controller:
    MKLookAroundViewController,
    context: Context
    ) {

        controller.scene = scene

        controller.isNavigationEnabled =
        false

        controller.showsRoadLabels =
        false
    }
}
// MARK: - Street Fair Service Model

private struct StreetFairService:
Identifiable {

    let id = UUID()

    let title: String
    let subtitle: String
    let icon: String
}