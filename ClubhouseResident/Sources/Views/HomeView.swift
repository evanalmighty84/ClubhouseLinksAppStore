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

                    Image("hoa")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .cyan.opacity(0.7), radius: 20)

                    // Hammering bird animation
                    HammeringBirdSpriteView()
                    .frame(width: 180, height: 180)
                    .padding(.top, -6)
                    .padding(.bottom, -14)

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
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .cyan.opacity(0.5), radius: 12)
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


// MARK: - Hammering Bird Sprite Animation

private struct HammeringBirdSpriteView: View {
    @State private var currentFrame = 0
    @State private var showLogo = false

    private let frames = (1...7).map {
        String(format: "clubhouse_bird_hammering_%02d", $0)
    }

    private let frameDuration: UInt64 = 300_000_000 // 0.30 seconds

    var body: some View {
        ZStack {
            if showLogo {
                Image("clubhouse_logo")
                .resizable()
                .scaledToFit()
                .transition(
                    .opacity.combined(with: .scale(scale: 0.85))
                )
            } else {
                Image(frames[currentFrame])
                .resizable()
                .scaledToFit()
                .shadow(color: .cyan.opacity(0.35), radius: 10)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await playAnimationOnce()
        }
        .accessibilityHidden(true)
    }

    @MainActor
    private func playAnimationOnce() async {
        for index in frames.indices {
            currentFrame = index

            do {
                try await Task.sleep(nanoseconds: frameDuration)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }
        }

        withAnimation(.easeInOut(duration: 0.45)) {
            showLogo = true
        }
    }
}