import SwiftUI
import AuthenticationServices

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var savedFirstName = ""
    @AppStorage("residentLastName") private var savedLastName = ""
    @AppStorage("residentPhone") private var savedPhone = ""
    @AppStorage("residentAddress") private var savedAddress = ""
    @AppStorage("residentApprovalStatus") private var residentApprovalStatus = ""
    @AppStorage("residentNeighborhoodId") private var residentNeighborhoodId = 0
    @AppStorage("residentDisplayAreaName") private var displayAreaName = ""
    @AppStorage("residentNeighborhoodName") private var residentNeighborhoodName = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentSignupProvider") private var residentSignupProvider = "email"
    @AppStorage("residentAppleUserId") private var residentAppleUserId = ""

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var neighborhoodCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    @State private var currentStep: SignupStep = .welcomeChoice
    @FocusState private var focusedField: SignupField?

    private let signupURL = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/signup"

    private let animatedTransition: AnyTransition =
    .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                        .foregroundStyle(errorMessage.lowercased().contains("successful") ? .green : .red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    }

                    ZStack {
                        currentStepView
                        .id(currentStep.id)
                        .transition(animatedTransition)
                    }
                    .animation(.easeInOut(duration: 0.4), value: currentStep)

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
        .onAppear {
            appleSignInCoordinator.onSuccess = { credential in
                handleAppleCredential(credential)
            }

            appleSignInCoordinator.onFailure = { error in
                if let authError = error as? ASAuthorizationError {
                    errorMessage = "Apple Sign In failed. Code: \(authError.code.rawValue)"
                } else {
                    errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Resident Sign Up")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            Text(headerSubtitle)
            .foregroundStyle(.white.opacity(0.78))
            .font(.subheadline)
            .multilineTextAlignment(.center)

            if currentStep.showsProgress {
                progressDots
            }
        }
        .padding(.top, 8)
    }

    private var headerSubtitle: String {
        switch currentStep {
        case .welcomeChoice:
            return "Create your resident account with a guided signup flow."
        case .appleWelcome:
            return "You’re almost done — let’s finish your resident profile."
        default:
            return "Answer one quick question at a time."
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(progressSteps.indices, id: \.self) { index in
                Circle()
                .fill(index <= progressIndex ? Color.cyan : Color.white.opacity(0.18))
                .frame(width: 10, height: 10)
                .shadow(color: index <= progressIndex ? .cyan.opacity(0.45) : .clear, radius: 6)
            }
        }
        .padding(.top, 4)
    }

    private var progressSteps: [SignupStep] {
        if residentSignupProvider == "apple" {
            return [.phone, .address, .inviteCode]
        } else {
            return [.firstName, .lastName, .phone, .address, .inviteCode]
        }
    }

    private var progressIndex: Int {
        guard let index = progressSteps.firstIndex(where: { $0 == currentStep }) else { return 0 }
        return index
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcomeChoice:
            welcomeChoiceCard

        case .appleWelcome:
            appleWelcomeCard

        case .firstName:
            questionCard(
                question: "What’s your first name?",
                subtitle: "This helps personalize your resident profile.",
                placeholder: "Enter First Name",
                text: $firstName,
                field: .firstName,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter your first name."
                        return
                    }
                    errorMessage = ""
                    goTo(.lastName, focus: .lastName)
                }
            )

        case .lastName:
            questionCard(
                question: "What’s your last name?",
                subtitle: "We’ll use this for your resident account.",
                placeholder: "Enter Last Name",
                text: $lastName,
                field: .lastName,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    guard !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter your last name."
                        return
                    }
                    errorMessage = ""
                    goTo(.phone, focus: .phone)
                }
            )

        case .phone:
            questionCard(
                question: "What’s your phone number?",
                subtitle: "This helps connect your account to your resident profile.",
                placeholder: "Enter Phone Number",
                text: $phone,
                field: .phone,
                keyboardType: .phonePad,
                buttonTitle: "Next",
                onNext: {
                    guard !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter your phone number."
                        return
                    }
                    errorMessage = ""
                    goTo(.address, focus: .address)
                }
            )

        case .address:
            questionCard(
                question: "What’s your address?",
                subtitle: "We’ll use this to match you to the right neighborhood and nearby vendor activity.",
                placeholder: "Enter Address",
                text: $address,
                field: .address,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter your address."
                        return
                    }
                    errorMessage = ""
                    goTo(.inviteCode, focus: .inviteCode)
                }
            )

        case .inviteCode:
            questionCard(
                question: "What’s your invite code?",
                subtitle: "Enter the neighborhood access code shared with your community.",
                placeholder: "Enter Invite Code",
                text: $neighborhoodCode,
                field: .inviteCode,
                keyboardType: .default,
                buttonTitle: isLoading ? "Creating..." : "Create Account",
                onNext: {
                    submitSignup()
                },
                isPrimaryDisabled: isLoading
            )
        }
    }

    private var welcomeChoiceCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Let’s get you set up")
                .font(.title.bold())
                .foregroundStyle(.white)

                Text("You can sign up with Apple for a faster experience, or continue with the full step-by-step flow.")
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
            }

            Button {
                residentSignupProvider = "email"
                residentAppleUserId = ""
                errorMessage = ""
                goTo(.firstName, focus: .firstName)
            } label: {
                Text("Start Step-by-Step Signup")
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
                .shadow(color: .cyan.opacity(0.4), radius: 10)
            }

            appleSignupButton
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
    }

    private var appleWelcomeCard: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text("Welcome, \(fullDisplayName)!")
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                Text("Your Apple sign in is connected. Now let’s finish your resident account.")
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
            }

            Button {
                errorMessage = ""
                goTo(.phone, focus: .phone)
            } label: {
                Text("Continue")
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
                .shadow(color: .cyan.opacity(0.4), radius: 10)
            }

            Button {
                errorMessage = ""
                residentSignupProvider = "email"
                residentAppleUserId = ""
                goTo(.firstName, focus: .firstName)
            } label: {
                Text("Use manual signup instead")
                .foregroundStyle(.cyan)
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
    }

    private var appleSignupButton: some View {
        Button {
            hideKeyboard()
            appleSignInCoordinator.startSignIn()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                .font(.title3.bold())

                Text("Sign up with Apple")
                .font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func questionCard(
    question: String,
    subtitle: String,
    placeholder: String,
    text: Binding<String>,
    field: SignupField,
    keyboardType: UIKeyboardType,
    buttonTitle: String,
    onNext: @escaping () -> Void,
    isPrimaryDisabled: Bool = false
    ) -> some View {
        VStack(spacing: 20) {
            HStack {
                if currentStep.canGoBack {
                    Button {
                        goBack()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(.cyan)
                        .font(.subheadline.bold())
                    }
                }

                Spacer()
            }

            VStack(spacing: 10) {
                Text(question)
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                Text(subtitle)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .font(.subheadline)
            }

            neonTextField(
                placeholder: placeholder,
                text: text,
                keyboardType: keyboardType
            )
            .focused($focusedField, equals: field)

            Button {
                hideKeyboard()
                onNext()
            } label: {
                Text(buttonTitle)
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
                .shadow(color: .cyan.opacity(0.35), radius: 10)
            }
            .disabled(isPrimaryDisabled)
            .opacity(isPrimaryDisabled ? 0.6 : 1)

        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = field
            }
        }
    }

    private func neonTextField(
    placeholder: String,
    text: Binding<String>,
    keyboardType: UIKeyboardType
    ) -> some View {
        TextField(placeholder, text: text)
        .font(.title3)
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            LinearGradient(
                colors: [
                    .white.opacity(0.08),
                    .purple.opacity(0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
            .stroke(.cyan.opacity(0.65), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .keyboardType(keyboardType)
        .textInputAutocapitalization(keyboardType == .default ? .words : .never)
        .autocorrectionDisabled()
    }

    private var fullDisplayName: String {
        let combined = "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return combined.isEmpty ? "Resident" : combined
    }

    private func goTo(_ step: SignupStep, focus: SignupField? = nil) {
        hideKeyboard()
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = step
        }

        if let focus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                focusedField = focus
            }
        } else {
            focusedField = nil
        }
    }

    private func goBack() {
        errorMessage = ""

        switch currentStep {
        case .firstName:
            goTo(.welcomeChoice)

        case .lastName:
            goTo(.firstName, focus: .firstName)

        case .phone:
            if residentSignupProvider == "apple" {
                goTo(.appleWelcome)
            } else {
                goTo(.lastName, focus: .lastName)
            }

        case .address:
            goTo(.phone, focus: .phone)

        case .inviteCode:
            goTo(.address, focus: .address)

        case .welcomeChoice, .appleWelcome:
            break
        }
    }

    private func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        errorMessage = ""

        residentSignupProvider = "apple"
        residentAppleUserId = credential.user

        let givenName = credential.fullName?.givenName ?? ""
        let familyName = credential.fullName?.familyName ?? ""

        if !givenName.isEmpty {
            firstName = givenName
        }

        if !familyName.isEmpty {
            lastName = familyName
        }

        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            goTo(.firstName, focus: .firstName)
            errorMessage = "Apple Sign In successful. Let’s finish your details."
            return
        }

        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            goTo(.lastName, focus: .lastName)
            errorMessage = "Apple Sign In successful. Let’s finish your details."
            return
        }

        goTo(.appleWelcome)
    }

    private func submitSignup() {
        errorMessage = ""

        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !neighborhoodCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please complete all fields."
            return
        }

        guard let url = URL(string: signupURL) else {
            errorMessage = "Invalid server URL."
            return
        }

        isLoading = true

        let payload: [String: String] = [
            "first_name": firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            "last_name": lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "address": address.trimmingCharacters(in: .whitespacesAndNewlines),
            "invite_code": neighborhoodCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
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

                    if decoded.success == true,
                    let resident = decoded.resident,
                    let newResidentId = decoded.resident_id {

                        residentId = newResidentId
                        savedFirstName = resident.first_name
                        savedLastName = resident.last_name
                        savedPhone = resident.phone
                        savedAddress = address
                        residentApprovalStatus = resident.approval_status
                        residentNeighborhoodId = resident.neighborhood_id ?? 0
                        displayAreaName = resident.display_area_name ?? ""
                        residentNeighborhoodName = resident.neighborhood_name ?? ""

                        if residentSignupProvider != "apple" {
                            residentSignupProvider = "email"
                        }

                        residentIsSignedUp = true
                        dismiss()
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

private enum SignupStep: Equatable {
    case welcomeChoice
    case appleWelcome
    case firstName
    case lastName
    case phone
    case address
    case inviteCode

    var id: String {
        switch self {
        case .welcomeChoice: return "welcomeChoice"
        case .appleWelcome: return "appleWelcome"
        case .firstName: return "firstName"
        case .lastName: return "lastName"
        case .phone: return "phone"
        case .address: return "address"
        case .inviteCode: return "inviteCode"
        }
    }

    var showsProgress: Bool {
        switch self {
        case .welcomeChoice, .appleWelcome:
            return false
        default:
            return true
        }
    }

    var canGoBack: Bool {
        switch self {
        case .welcomeChoice, .appleWelcome:
            return false
        default:
            return true
        }
    }
}

private enum SignupField: Hashable {
    case firstName
    case lastName
    case phone
    case address
    case inviteCode
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
    let display_area_name: String?
    let approval_status: String
    let sms_verified: Bool
}

final class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onSuccess: ((ASAuthorizationAppleIDCredential) -> Void)?
    var onFailure: ((Error) -> Void)?

    private var currentController: ASAuthorizationController?

    func startSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        currentController = controller
        controller.performRequests()
    }

    func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not read Apple sign in information."]
            )
            onFailure?(error)
            return
        }

        onSuccess?(credential)
    }

    func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
    ) {
        onFailure?(error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow }) {
            return window
        }

        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return window
        }

        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}