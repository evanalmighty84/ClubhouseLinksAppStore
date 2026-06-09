import SwiftUI
import AuthenticationServices

struct SignupView: View {
    @AppStorage("residentFirstName") private var savedFirstName = ""
    @AppStorage("residentLastName") private var savedLastName = ""
    @AppStorage("residentPhone") private var savedPhone = ""
    @AppStorage("residentAddress") private var savedAddress = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var neighborhoodCode = ""
    @State private var errorMessage = ""

    private let validNeighborhoodCode = "COUNTRYPLACE2026"

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Resident Sign Up")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    Text("Enter your resident details and the neighborhood access code shared with your community.")
                    .foregroundStyle(.white.opacity(0.75))

                    NeonTextField("First Name", text: $firstName)
                    NeonTextField("Last Name", text: $lastName)
                    NeonTextField("Phone", text: $phone)
                    NeonTextField("Address or Unit", text: $address)
                    NeonTextField("Neighborhood Code", text: $neighborhoodCode)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    }

                    Button {
                        submitSignup()
                    } label: {
                        Text("Create Resident Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    SignInWithAppleButton(.signUp) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            print("Apple signup success: \(authResults)")
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer(minLength: 80)
                }
                .padding()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitSignup() {
        errorMessage = ""

        guard !firstName.isEmpty,
        !lastName.isEmpty,
        !phone.isEmpty,
        !address.isEmpty else {
            errorMessage = "Please complete all fields."
            return
        }

        guard neighborhoodCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) == validNeighborhoodCode else {
            errorMessage = "Invalid neighborhood code."
            return
        }

        savedFirstName = firstName
        savedLastName = lastName
        savedPhone = phone
        savedAddress = address
        residentIsSignedUp = true

        print("Resident profile created")
    }
}