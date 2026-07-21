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
    @State private var showingDeletionSuccess = false


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
            "Permanently Delete Account?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Permanently Delete Account", role: .destructive) {
                deleteAccountPermanently()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text(
                "This will permanently delete your resident account and personal data. This action cannot be undone."
            )
        }
        .alert("Account Deleted", isPresented: $showingDeletionSuccess) {
            Button("OK") {
                clearLocalAccountAfterDeletion()
            }
        } message: {
            Text(
                "Your Clubhouse Links account and associated personal data have been permanently deleted."
            )
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

            Text("Permanently deleting your Clubhouse Links account will remove your resident profile and personal data connected to it, including your name, phone number, address, local area assignment, and account records. This action cannot be undone.")            .font(.subheadline)
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

                    Text(isDeletingAccount ? "Deleting Account..." : "Delete My Account")                    .font(.headline)
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

    private func deleteAccountPermanently() {
        guard residentId > 0 else {
            deleteMessage = "Resident profile not found."
            return
        }

        guard let url = URL(
            string: "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/delete-account"
        ) else {
            deleteMessage = "Invalid account deletion URL."
            return
        }

        isDeletingAccount = true
        deleteMessage = ""

        let payload: [String: Any] = [
            "resident_id": residentId
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isDeletingAccount = false
            deleteMessage = "Could not prepare the account deletion."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isDeletingAccount = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    deleteMessage = error.localizedDescription
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    deleteMessage = "The server returned an invalid response."
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                var message = "The account could not be deleted."

                if let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let serverError = json["error"] as? String,
                !serverError.isEmpty {
                    message = serverError
                }

                DispatchQueue.main.async {
                    deleteMessage = message
                }
                return
            }

            DispatchQueue.main.async {
                showingDeletionSuccess = true
            }
        }.resume()
    }

    private func clearLocalAccountAfterDeletion() {
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