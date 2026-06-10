import SwiftUI

struct ResidentProfileView: View {
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentNeighborhoodName") private var neighborhoodName = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Resident Profile")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    VStack(spacing: 10) {
                        Text("\(firstName) \(lastName)")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                        Text(neighborhoodName.isEmpty ? "Country Place" : neighborhoodName)
                        .font(.headline)
                        .foregroundStyle(.cyan)

                        Text(phone)
                        .foregroundStyle(.white.opacity(0.75))

                        Text(address)
                        .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    NeonCard(
                        title: "Community Updates",
                        text: "View announcements, HOA updates, and neighborhood news for your community."
                    )

                    NeonCard(
                        title: "Vendor Directory",
                        text: "Browse trusted local vendors connected to your neighborhood."
                    )

                    NeonCard(
                        title: "Events",
                        text: "See upcoming meetings, block parties, and neighborhood events."
                    )

                    Button {
                        residentIsSignedUp = false
                    } label: {
                        Text("Sign Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
        }
    }
}