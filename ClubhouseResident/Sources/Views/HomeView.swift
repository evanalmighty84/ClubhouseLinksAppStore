import SwiftUI

struct HomeView: View {
    var body: some View {
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

                    NeonCard(
                        title: "Community Updates",
                        text: "View HOA events, announcements, board updates, and neighborhood news."
                    )

                    NeonCard(
                        title: "Submit Requests",
                        text: "Send maintenance requests, report issues, or contact management."
                    )

                    NeonCard(
                        title: "Amenities",
                        text: "Access clubhouse, pool, tennis court, and community information."
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