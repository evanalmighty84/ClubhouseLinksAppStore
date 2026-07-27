import SwiftUI

struct HomeView: View {
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentId") private var residentId = 0

    var body: some View {
        if residentId > 0 || residentIsSignedUp {
            ResidentProfileView()
        } else {
            homeContent
        }
    }

    private var homeContent: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {

                    // Lightbulb appears first, then fades into
                    // the existing waving bird view.
                    HomeIntroHeroView()
                    .frame(height: 190)
                    .padding(.top, 4)
                    .padding(.bottom, -6)

                    // Tennis-court clubhouse image
                    Image("hoa")
                    .resizable()
                    .scaledToFit()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: .cyan.opacity(0.7),
                        radius: 20
                    )

                    VStack(spacing: 6) {
                        Text("Clubhouse Links")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                        Text("Home Services")
                        .font(.title2.bold())
                        .foregroundStyle(.cyan)

                        Text("Your Local Home Service Referral Network")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    }

                    NavigationLink {
                        SignupView()
                    } label: {
                        Text("Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
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
                        title: "Community Updates",
                        text: "View HOA block party events, neighborhood announcements, and neighborhood news."
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


// MARK: - Lightbulb to Waving Bird Intro

private struct HomeIntroHeroView: View {
    @State private var showWavingBird = false
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            if showWavingBird {
                FlyingBirdHeroView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.88)
                    )
                )
            } else {
                Image("clubhouse_app_icon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 30,
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
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.88)
                    )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            await startIntroOnce()
        }
        .accessibilityHidden(true)
    }

    @MainActor
    private func startIntroOnce() async {
        guard !hasStarted else {
            return
        }

        hasStarted = true

        // Show the lightbulb icon for 1.5 seconds.
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

        // Fade into the regular waving bird.
        withAnimation(
            .easeInOut(duration: 0.65)
        ) {
            showWavingBird = true
        }
    }
}