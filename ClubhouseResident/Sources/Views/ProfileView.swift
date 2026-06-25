import SwiftUI

struct ProfileView: View {
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false

    var body: some View {
        NeonBackground {
            VStack(alignment: .leading, spacing: 18) {
                Text("Resident Profile")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

                NeonCard(title: "Name", text: "\(firstName) \(lastName)")
                NeonCard(title: "Phone", text: phone)
                NeonCard(title: "Address", text: address)

                Button("Sign Out") {
                    residentIsSignedUp = false
                }
                .foregroundStyle(.red)

                Spacer()
            }
            .padding()
        }
    }
}