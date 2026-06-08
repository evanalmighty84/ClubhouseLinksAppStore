import SwiftUI

struct HomeView: View {
    var body: some View {
        NeonBackground {
            VStack(alignment: .leading, spacing: 22) {
                Text("Clubhouse Links")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Resident Portal")
                    .font(.title2.bold())
                    .foregroundStyle(.cyan)

                NeonCard(title: "Community Updates",
                         text: "View HOA events, neighborhood announcements, and resident resources.")

                NeonCard(title: "Submit Requests",
                         text: "Send service, maintenance, or community requests directly from the app.")

                Spacer()
            }
            .padding()
        }
    }
}
