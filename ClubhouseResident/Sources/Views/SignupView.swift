import SwiftUI
import AuthenticationServices

struct SignupView: View {
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var savedFirstName = ""
    @AppStorage("residentLastName") private var savedLastName = ""
    @AppStorage("residentPhone") private var savedPhone = ""
    @AppStorage("residentAddress") private var savedAddress = ""
    @AppStorage("residentApprovalStatus") private var residentApprovalStatus = ""
    @AppStorage("residentNeighborhoodId") private var residentNeighborhoodId = 0
    @AppStorage("residentNeighborhoodName") private var residentNeighborhoodName = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var neighborhoodCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    private let signupURL = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/signup"

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Resident Sign Up")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    Text("Enter your resident details and the neighborhood access code shared with your community.")
                    .foregroundStyle(.white.opacity(0.75))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("First Name")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.headline)

                        NeonTextField("Enter First Name", text: $firstName)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last Name")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.headline)

                        NeonTextField("Enter Last Name", text: $lastName)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.headline)

                        NeonTextField("Enter Phone Number", text: $phone)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.headline)

                        NeonTextField("Enter Address", text: $address)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Invite Code")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.headline)

                        NeonTextField("Enter Invite Code", text: $neighborhoodCode)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                        .foregroundStyle(errorMessage.contains("successful") ? .green : .red)
                        .font(.subheadline)
                    }

                    Button {
                        hideKeyboard()
                        submitSignup()
                    } label: {
                        Text(isLoading ? "Creating..." : "Create Account")
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
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isLoading)

                    SignInWithAppleButton(.signUp) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            handleAppleSignInSuccess(authResults)

                        case .failure(let error):
                            if let authError = error as? ASAuthorizationError {
                                errorMessage = "Apple Sign In failed. Code: \(authError.code.rawValue)"
                            } else {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer(minLength: 80)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleAppleSignInSuccess(_ authResults: ASAuthorization) {
        errorMessage = ""

        guard let credential = authResults.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Could not read Apple sign in information."
            return
        }

        let givenName = credential.fullName?.givenName ?? ""
        let familyName = credential.fullName?.familyName ?? ""

        if !givenName.isEmpty {
            firstName = givenName
        }

        if !familyName.isEmpty {
            lastName = familyName
        }

        errorMessage = "Apple Sign In successful. Please enter your phone number, address, and neighborhood code to finish creating your resident account."
    }

    private func submitSignup() {
        errorMessage = ""

        guard !firstName.isEmpty,
        !lastName.isEmpty,
        !phone.isEmpty,
        !address.isEmpty,
        !neighborhoodCode.isEmpty else {
            errorMessage = "Please complete all fields."
            return
        }

        guard let url = URL(string: signupURL) else {
            errorMessage = "Invalid server URL."
            return
        }

        isLoading = true

        let payload: [String: String] = [
            "first_name": firstName,
            "last_name": lastName,
            "phone": phone,
            "address": address,
            "invite_code": neighborhoodCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    errorMessage = "No response from server."
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(SignupResponse.self, from: data)

                    if decoded.success == true, let resident = decoded.resident, let newResidentId = decoded.resident_id {
                        residentId = newResidentId
                        savedFirstName = resident.first_name
                        savedLastName = resident.last_name
                        savedPhone = resident.phone
                        savedAddress = address
                        residentApprovalStatus = resident.approval_status
                        residentNeighborhoodId = resident.neighborhood_id ?? 0
                        residentNeighborhoodName = resident.neighborhood_name ?? ""
                        residentIsSignedUp = true
                    } else {
                        errorMessage = decoded.error ?? "Signup failed."
                    }
                } catch {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "Unreadable response"
                    errorMessage = rawResponse
                    print(rawResponse)
                }
            }
        }.resume()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct SignupResponse: Codable {
    let success: Bool?
    let resident_id: Int?
    let resident: ResidentAccount?
    let message: String?
    let error: String?
}

struct ResidentAccount: Codable {
    let id: Int
    let first_name: String
    let last_name: String
    let phone: String
    let neighborhood_id: Int?
    let neighborhood_name: String?
    let approval_status: String
    let sms_verified: Bool
}