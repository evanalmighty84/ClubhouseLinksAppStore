import SwiftUI

struct HomeView: View {
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var firstName = ""

    var body: some View {
        if residentIsSignedUp {
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

                    VStack(spacing: 6) {
                        Text("Clubhouse Links")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                        Text("Resident Portal")
                        .font(.title2.bold())
                        .foregroundStyle(.cyan)

                        Text("Stay connected with your HOA community")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    }

                    if residentId > 0 {
                        Button {
                            residentIsSignedUp = true
                        } label: {
                            Text(firstName.isEmpty ? "Resident Sign In" : "Sign In as \(firstName)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.14))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .cyan.opacity(0.25), radius: 10)
                        }
                    }

                    NavigationLink {
                        SignupView()
                    } label: {
                        Text("Create Resident Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .cyan.opacity(0.5), radius: 12)
                    }

                    NeonCard(
                        title: "Community Updates",
                        text: "View HOA events, announcements, board updates, and neighborhood news."
                    )

                    NeonCard(
                        title: "Submit Vendor Requests",
                        text: "Send maintenance requests, report issues, or contact management."
                    )

                    NeonCard(
                        title: "Book Amenities",
                        text: "Contact your HOA to access clubhouse, pool, tennis court, and community information."
                    )

                    NeonCard(
                        title: "View Vendors",
                        text: "Browse trusted local contractors, home service providers, and HOA-approved businesses."
                    )

                    NeonCard(
                        title: "Upcoming Events",
                        text: "See social events, meetings, holiday celebrations, and HOA activities."
                    )
                }
                .padding()
            }
        }
    }
}