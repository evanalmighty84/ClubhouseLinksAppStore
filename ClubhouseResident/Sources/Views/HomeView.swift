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

    private let frames = (1...7).map {
        String(format: "clubhouse_bird_hammering_%02d", $0)
    }

    private let timer = Timer.publish(
        every: 0.10,
        on: .main,
        in: .common
    )
    .autoconnect()

    var body: some View {
        Image(frames[currentFrame])
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: .cyan.opacity(0.35), radius: 10)
        .onReceive(timer) { _ in
            currentFrame = (currentFrame + 1) % frames.count
        }
        .accessibilityHidden(true)
    }
}