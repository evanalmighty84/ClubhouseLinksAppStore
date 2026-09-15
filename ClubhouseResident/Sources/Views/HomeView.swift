import SwiftUI

struct HomeView: View {

    @AppStorage("residentIsSignedUp")
    private var residentIsSignedUp = false

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("accountType")
    private var accountType = ""

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("supportResidentMode")
    private var supportResidentMode = false

    @AppStorage("supportSignupMode")
    private var supportSignupMode = false

    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage("residentHomeMode")
    private var residentHomeMode = "standard"

    @AppStorage("residentNeighborhoodName")
    private var residentNeighborhoodName = ""

    @AppStorage("residentNeighborhoodId")
    private var residentNeighborhoodId = 0

    @State
    private var resolvedHomeModeResidentId = 0

    @State
    private var isRefreshingHomeMode = false

    var body: some View {

        Group {

            /*
             * New-signup testing always wins first.
             */
            if supportSignupMode {

                SupportSignupContainerView()

                /*
                 * Before displaying a resident screen,
                 * resolve their neighborhood's CURRENT
                 * home mode from Postgres.
                 */
            } else if shouldResolveResidentHomeMode &&
            resolvedHomeModeResidentId != residentId {

                homeModeLoadingView

                /*
                 * Aspen is supporting an existing resident.
                 */
            } else if supportResidentMode &&
            residentId > 0 {

                residentDestination

                /*
                 * Normal vendor account.
                 */
            } else if accountType == "vendor" &&
            vendorId > 0 {

                VendorHomeView()

                /*
                 * Normal resident account.
                 */
            } else if residentId > 0 ||
            residentIsSignedUp {

                residentDestination

            } else {

                homeContent
            }
        }

        /*
         * Resident changed:
         *
         * - normal login
         * - signup completed
         * - Aspen switched resident
         *
         * Resolve the mode again.
         */
        .task(id: residentId) {

            guard residentId > 0 else {

                resolvedHomeModeResidentId = 0

                return
            }

            await refreshResidentHomeMode(
                residentId: residentId
            )
        }

        /*
         * This is what makes your SQL command
         * a real remote ON/OFF switch.
         *
         * When the app comes back to the foreground,
         * check Postgres again.
         */
        .onChange(
            of: scenePhase
        ) { newPhase in

            guard
            newPhase == .active,
            residentId > 0
            else {
                return
            }

            Task {

                await refreshResidentHomeMode(
                    residentId: residentId,
                    force: true
                )
            }
        }
    }

    private var homeContent: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {

                    HomeIntroImageView()
                    .frame(height: 250)

                    VStack(spacing: 6) {

                        Text("Clubhouse Links")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                        Text("Home Services")
                        .font(.title2.bold())
                        .foregroundStyle(.cyan)

                        Text(
                            "Your Local Home Service Referral Network"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(0.7)
                        )
                        .multilineTextAlignment(
                            .center
                        )
                    }

                    NavigationLink {
                        SignupView()
                    } label: {

                        Text("Create Account")
                        .font(.headline)
                        .frame(
                            maxWidth: .infinity
                        )
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
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                        .shadow(
                            color:
                            .cyan.opacity(0.5),
                            radius: 12
                        )
                    }

                    NeonCard(
                        title:
                        "See Completed Projects By Neighbors",
                        text:
                        "Choose your next home project or repair specialist by seeing who your neighbors have used"
                    )

                    NeonCard(
                        title:
                        "Submit Vendor Requests",
                        text:
                        "Send maintenance requests, report issues, or contact reputable local vendors."
                    )

                    NeonCard(
                        title:
                        "View Vendors",
                        text:
                        "Browse trusted local contractors, home service providers, and HOA or neighborhood-reviewed businesses."
                    )

                    NeonCard(
                        title:
                        "Upcoming Events",
                        text:
                        "See social events, meetings, holiday celebrations, and other activities."
                    )

                    Spacer(minLength: 90)
                }
                .padding()
            }
        }
    }

    private var shouldResolveResidentHomeMode:
    Bool {

        guard residentId > 0 else {
            return false
        }

        /*
         * Normal resident.
         */
        if accountType != "vendor" {
            return true
        }

        /*
         * Aspen temporarily viewing a resident.
         */
        if supportResidentMode {
            return true
        }

        return false
    }


    @ViewBuilder
    private var residentDestination:
    some View {

        if residentHomeMode
        .lowercased()
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) == "street_fair" {

            StreetFairResidentView()

        } else {

            ResidentProfileView()
        }
    }


    private var homeModeLoadingView:
    some View {

        NeonBackground {

            VStack(spacing: 18) {

                ProgressView()
                .scaleEffect(1.2)
                .tint(.cyan)

                Text(
                    "Loading your neighborhood..."
                )
                .font(.headline)
                .foregroundStyle(.white)

                Text(
                    "Checking your Clubhouse Links experience."
                )
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }


    @MainActor
    private func refreshResidentHomeMode(
    residentId targetResidentId: Int,
    force: Bool = false
    ) async {

        guard targetResidentId > 0 else {
            return
        }

        /*
         * Don't issue duplicate requests.
         */
        guard !isRefreshingHomeMode else {
            return
        }

        /*
         * Unless this is an app-foreground refresh,
         * don't reload a resident we already resolved.
         */
        if !force &&
        resolvedHomeModeResidentId ==
        targetResidentId {

            return
        }

        isRefreshingHomeMode = true

        defer {
            isRefreshingHomeMode = false
        }

        do {

            let response =
            try await
            ResidentHomeModeAPI.shared
            .getHomeMode(
                residentId:
                targetResidentId
            )

            /*
             * Resident could have changed while the
             * request was in flight.
             */
            guard residentId ==
            targetResidentId
            else {
                return
            }

            let mode =
            response
            .resident_home_mode?
            .lowercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? "standard"

            residentHomeMode =
            mode.isEmpty
            ? "standard"
            : mode

            if let neighborhoodId =
            response.neighborhood_id {

                residentNeighborhoodId =
                neighborhoodId
            }

            if let neighborhoodName =
            response.neighborhood_name,
            !neighborhoodName.isEmpty {

                residentNeighborhoodName =
                neighborhoodName
            }

            resolvedHomeModeResidentId =
            targetResidentId

            print(
                "[Resident Home Mode]",
                "resident:",
                targetResidentId,
                "neighborhood:",
                residentNeighborhoodName,
                "mode:",
                residentHomeMode
            )

        } catch {

            /*
             * If the server is temporarily unavailable,
             * don't trap the user on a loading screen.
             *
             * Keep the last locally-known mode.
             */
            print(
                "[Resident Home Mode] Refresh failed:",
                error.localizedDescription
            )

            resolvedHomeModeResidentId =
            targetResidentId
        }
    }
}


// MARK: - Support Signup Container

/*
 * This wraps the REAL SignupView.
 *
 * It lets Aspen test:
 *
 * - resident registration
 * - phone number entry
 * - Twilio verification
 * - six-digit SMS AutoFill
 * - account creation
 *
 * while keeping the Aspen vendor account underneath.
 */
struct SupportSignupContainerView: View {

    // MARK: Vendor State

    @AppStorage("accountType")
    private var accountType = ""

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("vendorCompanyName")
    private var vendorCompanyName = ""

    @AppStorage("vendorCategory")
    private var vendorCategory = ""

    @AppStorage("vendorLogoURL")
    private var vendorLogoURL = ""

    // MARK: Resident State

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentIsSignedUp")
    private var residentIsSignedUp = false

    @AppStorage("residentFirstName")
    private var residentFirstName = ""

    @AppStorage("residentLastName")
    private var residentLastName = ""

    @AppStorage("residentPhone")
    private var residentPhone = ""

    @AppStorage("residentAddress")
    private var residentAddress = ""

    @AppStorage("residentNeighborhoodName")
    private var residentNeighborhoodName = ""

    @AppStorage("residentDisplayAreaName")
    private var residentDisplayAreaName = ""

    // MARK: Support State

    @AppStorage("supportSignupMode")
    private var supportSignupMode = false

    @AppStorage("supportResidentMode")
    private var supportResidentMode = false

    // MARK: Preserve Aspen Vendor Session

    @State private var originalVendorId = 0
    @State private var originalCompanyName = ""
    @State private var originalVendorCategory = ""
    @State private var originalVendorLogoURL = ""

    @State private var capturedVendorState = false
    @State private var finishingSignup = false

    var body: some View {

        SignupView()

        /*
         * Persistent support-mode banner.
         *
         * safeAreaInset prevents it from simply
         * covering the SignupView fields.
         */
        .safeAreaInset(
            edge: .top
        ) {
            supportSignupBanner
        }

        .onAppear {
            captureVendorStateIfNeeded()
        }

        /*
         * SignupView may change residentId as
         * soon as the new account is created.
         */


        /*
         * Some signup implementations set this
         * after SMS verification succeeds.
         */

    }


    // MARK: - Support Banner

    private var supportSignupBanner: some View {

        VStack(spacing: 10) {

            HStack(spacing: 10) {

                Image(
                    systemName:
                    "person.badge.plus"
                )
                .font(.headline)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("SUPPORT TEST MODE")
                    .font(.caption.bold())
                    .tracking(1.1)

                    Text("Testing New Resident Signup")
                    .font(.caption)
                }

                Spacer()

                Circle()
                .fill(.green)
                .frame(
                    width: 8,
                    height: 8
                )
            }

            Button {
                returnToAspen()
            } label: {

                HStack {

                    Image(
                        systemName:
                        "arrow.uturn.backward.circle.fill"
                    )

                    Text("Cancel & Return to Aspen")
                    .font(.caption.bold())

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    .orange.opacity(0.88)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            .black.opacity(0.92)
        )
        .overlay(
            Rectangle()
            .frame(height: 1)
            .foregroundStyle(
                .orange.opacity(0.75)
            ),
            alignment: .bottom
        )
    }


    // MARK: - Preserve Vendor

    private func captureVendorStateIfNeeded() {

        guard !capturedVendorState else {
            return
        }

        capturedVendorState = true

        originalVendorId = vendorId
        originalCompanyName = vendorCompanyName
        originalVendorCategory = vendorCategory
        originalVendorLogoURL = vendorLogoURL

        print(
            "[Support Signup] Preserved vendor:",
            originalVendorId,
            originalCompanyName
        )
    }


    // MARK: - Signup Completed




    // MARK: - Cancel Signup

    private func returnToAspen() {

        /*
         * Restore vendor identity.
         */
        accountType = "vendor"

        if originalVendorId > 0 {
            vendorId = originalVendorId
        }

        if !originalCompanyName.isEmpty {
            vendorCompanyName =
            originalCompanyName
        }

        if !originalVendorCategory.isEmpty {
            vendorCategory =
            originalVendorCategory
        }

        if !originalVendorLogoURL.isEmpty {
            vendorLogoURL =
            originalVendorLogoURL
        }

        /*
         * Clear temporary signup/resident UI state.
         */
        residentId = 0
        residentIsSignedUp = false

        residentFirstName = ""
        residentLastName = ""
        residentPhone = ""
        residentAddress = ""
        residentNeighborhoodName = ""
        residentDisplayAreaName = ""

        UserDefaults.standard.removeObject(
            forKey: "residentNeighborhoodId"
        )

        supportResidentMode = false
        supportSignupMode = false

        /*
         * Aspen stays registered normally.
         */
        VendorPushRegistration
        .syncStoredToken()

        print(
            "[Support Signup] Returned to Aspen"
        )
    }
}


// MARK: - Logo to Clubhouse Transition

struct HomeIntroImageView: View {

    @State private var showClubhouse = false
    @State private var hasStarted = false

    var body: some View {

        ZStack {

            logoImage
            .opacity(
                showClubhouse ? 0 : 1
            )
            .scaleEffect(
                showClubhouse ? 0.96 : 1
            )

            clubhouseImage
            .opacity(
                showClubhouse ? 1 : 0
            )
            .scaleEffect(
                showClubhouse ? 1 : 0.96
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .task {
            await startIntroOnce()
        }
    }


    private var logoImage: some View {

        Image("clubhouse_app_icon")
        .resizable()
        .interpolation(.high)
        .scaledToFit()
        .frame(
            width: 190,
            height: 190
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 38,
                style: .continuous
            )
        )
        .shadow(
            color:
            .cyan.opacity(0.65),
            radius: 18
        )
        .shadow(
            color:
            .purple.opacity(0.45),
            radius: 24
        )
    }


    private var clubhouseImage: some View {

        Image("hoa")
        .resizable()
        .interpolation(.high)
        .scaledToFit()
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
                LinearGradient(
                    colors: [
                        .cyan.opacity(0.7),
                        .orange.opacity(0.75),
                        .purple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        }
        .shadow(
            color:
            .cyan.opacity(0.7),
            radius: 20
        )
    }


    @MainActor
    private func startIntroOnce() async {

        guard !hasStarted else {
            return
        }

        hasStarted = true

        do {

            try await Task.sleep(
                nanoseconds:
                1_500_000_000
            )

        } catch {

            return
        }

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .easeInOut(
                duration: 0.8
            )
        ) {
            showClubhouse = true
        }
    }
}