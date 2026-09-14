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

    var body: some View {

        /*
         * Support signup has highest priority.
         *
         * Aspen remains the underlying vendor account,
         * but we temporarily display the real SignupView
         * so we can test the complete resident signup /
         * Twilio verification flow.
         */
        if supportSignupMode {

            SupportSignupContainerView()

        } else if supportResidentMode &&
        residentId > 0 {

            /*
             * Existing resident support mode.
             */
            ResidentProfileView()

        } else if accountType == "vendor" &&
        vendorId > 0 {

            /*
             * Normal Aspen/vendor mode.
             */
            VendorHomeView()

        } else if residentId > 0 ||
        residentIsSignedUp {

            /*
             * Normal resident mode.
             */
            ResidentProfileView()

        } else {

            homeContent
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