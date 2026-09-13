import SwiftUI

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

    var body: some View {

        /*
         * Support mode MUST be checked first.
         *
         * Aspen remains logged in as a vendor,
         * but residentId temporarily points to
         * the resident being supported.
         */
        if supportResidentMode &&
        residentId > 0 {

            ResidentProfileView()

        } else if accountType == "vendor" &&
        vendorId > 0 {

            VendorHomeView()

        } else if residentId > 0 ||
        residentIsSignedUp {

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

                        Text("Your Local Home Service Referral Network")
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
                            color: .cyan.opacity(0.5),
                            radius: 12
                        )
                    }

                    NeonCard(
                        title: "See Completed Projects By Neighbors",
                        text: "Choose your next home project or repair specialist by seeing who your neighbors have used"
                    )

                    NeonCard(
                        title: "Submit Vendor Requests",
                        text: "Send maintenance requests, report issues, or contact reputable local vendors."
                    )

                    NeonCard(
                        title: "View Vendors",
                        text: "Browse trusted local contractors, home service providers, and HOA or neighborhood-reviewed businesses."
                    )

                    NeonCard(
                        title: "Upcoming Events",
                        text: "See social events, meetings, holiday celebrations, and other activities."
                    )

                    Spacer(minLength: 90)
                }
                .padding()
            }
        }
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
            color: .cyan.opacity(0.65),
            radius: 18
        )
        .shadow(
            color: .purple.opacity(0.45),
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
            color: .cyan.opacity(0.7),
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
                nanoseconds: 1_500_000_000
            )
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .easeInOut(duration: 0.8)
        ) {
            showClubhouse = true
        }
    }
}