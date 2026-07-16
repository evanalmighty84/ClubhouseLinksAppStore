import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var savedFirstName = ""
    @AppStorage("residentLastName") private var savedLastName = ""
    @AppStorage("residentPhone") private var savedPhone = ""
    @AppStorage("residentAddress") private var savedAddress = ""
    @AppStorage("residentNeighborhoodName") private var savedNeighborhoodName = ""
    @AppStorage("residentDisplayAreaName") private var savedDisplayAreaName = ""
    @AppStorage("residentSignupProvider") private var residentSignupProvider = "email"
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentAppleUserId") private var residentAppleUserId = ""

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var saveMessage = ""

    @State private var showingDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteMessage = ""

    private var profileAreaName: String {
        let cleanNeighborhood = savedNeighborhoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDisplayArea = savedDisplayAreaName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleanNeighborhood.isEmpty {
            return cleanNeighborhood
        }

        if !cleanDisplayArea.isEmpty {
            return cleanDisplayArea
        }

        return "Local Customer Area"
    }

    private var signupMethodLabel: String {
        residentSignupProvider.lowercased() == "apple" ? "Apple" : "Email / Manual"
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Account Settings")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Text("Manage your resident profile information for this device.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))

                    settingsCard

                    accountInfoCard

                    Button {
                        saveLocalProfile()
                    } label: {
                        Text("Save Changes")
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
                        .shadow(color: .cyan.opacity(0.4), radius: 12)
                    }

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                        .font(.subheadline.bold())
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    }

                    deleteAccountCard

                    Spacer(minLength: 80)
                }
                .padding()
            }
        }
        .onAppear {
            firstName = savedFirstName
            lastName = savedLastName
            phone = savedPhone
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, Delete My Account", role: .destructive) {
                requestAccountDeletion()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will submit a permanent account deletion request. Clubhouse Links will delete your resident account and personal data connected to it.")
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profile")
            .font(.title2.bold())
            .foregroundStyle(.white)

            TextField("First Name", text: $firstName)
            .textInputAutocapitalization(.words)
            .padding()
            .foregroundStyle(.white)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                .stroke(.cyan.opacity(0.7), lineWidth: 1)
            )

            TextField("Last Name", text: $lastName)
            .textInputAutocapitalization(.words)
            .padding()
            .foregroundStyle(.white)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                .stroke(.cyan.opacity(0.7), lineWidth: 1)
            )

            TextField("Phone", text: $phone)
            .keyboardType(.phonePad)
            .padding()
            .foregroundStyle(.white)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                .stroke(.cyan.opacity(0.7), lineWidth: 1)
            )

            Text("Address is used for local area matching and nearby vendor activity. To protect location accuracy, address changes require creating a new profile or contacting support.")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.58))
            .lineSpacing(3)
        }
        .padding(18)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
    }

    private var accountInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Info")
            .font(.title2.bold())
            .foregroundStyle(.white)

            infoRow(title: "Resident ID", value: residentId > 0 ? "\(residentId)" : "Not set")
            infoRow(title: "Area", value: profileAreaName)
            infoRow(title: "Signup Method", value: signupMethodLabel)
            infoRow(title: "Address", value: savedAddress.isEmpty ? "Not set" : savedAddress)
        }
        .padding(18)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
            .stroke(.purple.opacity(0.45), lineWidth: 1)
        )
    }

    private var deleteAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete Account")
            .font(.title2.bold())
            .foregroundStyle(.red.opacity(0.95))

            Text("You can request permanent deletion of your Clubhouse Links account from inside the app. We will delete your resident profile and personal data connected to it, including your name, phone number, address, local area assignment, and account records, unless we are legally required to retain limited information.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.72))
            .lineSpacing(4)

            Button {
                showingDeleteConfirm = true
            } label: {
                HStack {
                    if isDeletingAccount {
                        ProgressView()
                        .tint(.white)
                    }

                    Text(isDeletingAccount ? "Submitting Deletion Request..." : "Delete My Account")
                    .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red.opacity(0.78))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(isDeletingAccount)

            if !deleteMessage.isEmpty {
                Text(deleteMessage)
                .font(.caption.bold())
                .foregroundStyle(.cyan)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(.red.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
            .stroke(.red.opacity(0.55), lineWidth: 1)
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
            .font(.subheadline.bold())
            .foregroundStyle(.cyan)

            Spacer()

            Text(value)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.78))
            .multilineTextAlignment(.trailing)
        }
    }

    private func saveLocalProfile() {
        savedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        savedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        savedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        saveMessage = "Account settings saved."
    }

    private func requestAccountDeletion() {
        guard residentId > 0 else {
            deleteMessage = "Resident profile not found."
            return
        }

        isDeletingAccount = true
        deleteMessage = ""

        let urlString = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/account-deletion-request"

        guard let url = URL(string: urlString) else {
            isDeletingAccount = false
            deleteMessage = "Invalid deletion request URL."
            return
        }

        let payload: [String: Any] = [
            "resident_id": residentId,
            "first_name": savedFirstName,
            "last_name": savedLastName,
            "phone": savedPhone,
            "address": savedAddress,
            "signup_provider": residentSignupProvider,
            "apple_user_id": residentAppleUserId
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isDeletingAccount = false
            deleteMessage = "Could not prepare deletion request."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isDeletingAccount = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    deleteMessage = error.localizedDescription
                }
                return
            }

            DispatchQueue.main.async {
                deleteMessage = "Your account deletion request has been submitted. Clubhouse Links will make sure your account and personal data are deleted."

                clearLocalAccountAfterDeletionRequest()
            }
        }.resume()
    }

    private func clearLocalAccountAfterDeletionRequest() {
        let keysToRemove = [
            "residentId",
            "residentFirstName",
            "residentLastName",
            "residentPhone",
            "residentAddress",
            "residentApprovalStatus",
            "residentNeighborhoodId",
            "residentNeighborhoodName",
            "residentDisplayAreaName",
            "residentIsSignedUp",
            "residentSignupProvider",
            "residentAppleUserId"
        ]

        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        residentId = 0
        savedFirstName = ""
        savedLastName = ""
        savedPhone = ""
        savedAddress = ""
        savedNeighborhoodName = ""
        savedDisplayAreaName = ""
        residentSignupProvider = "email"
        residentAppleUserId = ""
        residentIsSignedUp = false
    }
}