import SwiftUI
import MapKit

// MARK: - Apple Maps Address Autocomplete

final class AddressAutocomplete: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var errorMessage = ""

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()

        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedQuery.count >= 3 else {
            suggestions = []
            return
        }

        completer.queryFragment = trimmedQuery
    }

    func clear() {
        completer.queryFragment = ""
        suggestions = []
        errorMessage = ""
    }

    func completerDidUpdateResults(
    _ completer: MKLocalSearchCompleter
    ) {
        DispatchQueue.main.async {
            self.suggestions = Array(completer.results.prefix(5))
            self.errorMessage = ""
        }
    }

    func completer(
    _ completer: MKLocalSearchCompleter,
    didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.suggestions = []
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Signup View

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

    @StateObject private var addressAutocomplete = AddressAutocomplete()

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var verificationCode = ""
    @State private var verifiedPhone = ""
    @State private var address = ""
    @State private var neighborhoodCode = ""

    @State private var errorMessage = ""
    @State private var verificationMessage = ""

    @State private var isLoading = false
    @State private var isSendingVerification = false
    @State private var isCheckingVerification = false
    @State private var isSelectingAddress = false

    @State private var currentStep: SignupStep = .welcomeChoice
    @FocusState private var focusedField: SignupField?

    private let signupURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/signup"

    private let sendVerificationURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/send-verification"

    private let checkVerificationURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/check-verification"

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
                        .foregroundStyle(
                            errorMessage
                            .lowercased()
                            .contains("successful")
                            ? .green
                            : .red
                        )
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    }

                    ZStack {
                        currentStepView
                        .id(currentStep.id)
                        .transition(animatedTransition)
                    }
                    .animation(
                        .easeInOut(duration: 0.4),
                        value: currentStep
                    )

                    Spacer(minLength: 80)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Create Your Account")
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
            return "Join Clubhouse Links and discover nearby communities and trusted local services."

        default:
            return "Answer one quick question at a time."
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(progressSteps.indices, id: \.self) { index in
                Circle()
                .fill(
                    index <= progressIndex
                    ? Color.cyan
                    : Color.white.opacity(0.18)
                )
                .frame(width: 10, height: 10)
                .shadow(
                    color: index <= progressIndex
                    ? .cyan.opacity(0.45)
                    : .clear,
                    radius: 6
                )
            }
        }
        .padding(.top, 4)
    }

    private var progressSteps: [SignupStep] {
        [
            .firstName,
            .lastName,
            .phone,
            .verifyPhone,
            .address,
            .inviteCode
        ]
    }

    private var progressIndex: Int {
        guard let index = progressSteps.firstIndex(
            where: { $0 == currentStep }
        ) else {
            return 0
        }

        return index
    }

    // MARK: - Signup Steps

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcomeChoice:
            welcomeChoiceCard

        case .firstName:
            questionCard(
                question: "What’s your first name?",
                subtitle: "This helps personalize your Clubhouse Links experience.",
                placeholder: "Enter First Name",
                text: $firstName,
                field: .firstName,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    let trimmedName = firstName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !trimmedName.isEmpty else {
                        errorMessage = "Please enter your first name."
                        return
                    }

                    firstName = trimmedName
                    errorMessage = ""
                    goTo(.lastName, focus: .lastName)
                }
            )

        case .lastName:
            questionCard(
                question: "What’s your last name?",
                subtitle: "We’ll use this to create your account.",
                placeholder: "Enter Last Name",
                text: $lastName,
                field: .lastName,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    let trimmedName = lastName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !trimmedName.isEmpty else {
                        errorMessage = "Please enter your last name."
                        return
                    }

                    lastName = trimmedName
                    errorMessage = ""
                    goTo(.phone, focus: .phone)
                }
            )

        case .phone:
            questionCard(
                question: "What’s your mobile number?",
                subtitle: "We’ll text you a one-time verification code to secure your account.",
                placeholder: "Enter Mobile Number",
                text: $phone,
                field: .phone,
                keyboardType: .phonePad,
                buttonTitle: phoneButtonTitle,
                onNext: {
                    if isPhoneVerifiedForCurrentNumber {
                        errorMessage = ""
                        goTo(.address, focus: .address)
                    } else {
                        sendVerificationCode()
                    }
                },
                isPrimaryDisabled: isSendingVerification
            )
            .onChange(of: phone) { _ in
                handlePhoneNumberChange()
            }

        case .verifyPhone:
            phoneVerificationCard

        case .address:
            addressAutocompleteCard

        case .inviteCode:
            questionCard(
                question: "Do you have an invite code?",
                subtitle: "Optional. Enter a code from a participating community or local business, or continue without one.",
                placeholder: "Invite Code (Optional)",
                text: $neighborhoodCode,
                field: .inviteCode,
                keyboardType: .default,
                buttonTitle: inviteCodeButtonTitle,
                onNext: {
                    submitSignup()
                },
                isPrimaryDisabled: isLoading
            )
        }
    }

    private var inviteCodeButtonTitle: String {
        if isLoading {
            return "Creating..."
        }

        let trimmedCode = neighborhoodCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmedCode.isEmpty
        ? "Skip & Create Account"
        : "Create Account"
    }

    // MARK: - Welcome Card

    private var welcomeChoiceCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Let’s get you set up")
                .font(.title.bold())
                .foregroundStyle(.white)

                Text(
                    "Create your account to discover nearby communities, events, and trusted local services."
                )
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
            }

            primaryButton(
                title: "Start Step-by-Step Signup",
                disabled: false
            ) {
                errorMessage = ""
                goTo(.firstName, focus: .firstName)
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

    // MARK: - Phone Verification

    private var phoneVerificationCard: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    verificationCode = ""
                    verificationMessage = ""
                    errorMessage = ""
                    goTo(.phone, focus: .phone)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(.cyan)
                    .font(.subheadline.bold())
                }

                Spacer()
            }

            VStack(spacing: 10) {
                Text("Enter your verification code")
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                Text(
                    "We sent a six-digit code to \(formattedPhoneForDisplay)."
                )
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .font(.subheadline)
            }

            TextField(
                "Verification Code",
                text: $verificationCode
            )
            .font(.title2)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
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
                .stroke(
                    .cyan.opacity(0.65),
                    lineWidth: 1.5
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused(
                $focusedField,
                equals: .verificationCode
            )
            .onChange(of: verificationCode) { newValue in
                verificationCode = String(
                    newValue
                    .filter(\.isNumber)
                    .prefix(6)
                )
            }

            if !verificationMessage.isEmpty {
                Text(verificationMessage)
                .font(.caption)
                .foregroundStyle(
                    isPhoneVerifiedForCurrentNumber
                    ? .green
                    : .white.opacity(0.72)
                )
                .multilineTextAlignment(.center)
            }

            primaryButton(
                title: isCheckingVerification
                ? "Verifying..."
                : "Verify and Continue",
                disabled:
                isCheckingVerification ||
                verificationCode.count != 6
            ) {
                checkVerificationCode()
            }

            Button {
                sendVerificationCode(isResend: true)
            } label: {
                Text(
                    isSendingVerification
                    ? "Sending..."
                    : "Send a new code"
                )
                .foregroundStyle(.cyan)
                .font(.subheadline.bold())
            }
            .disabled(isSendingVerification)
            .opacity(isSendingVerification ? 0.6 : 1)
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
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                focusedField = .verificationCode
            }
        }
    }

    // MARK: - Address Card

    // MARK: - Address Card

    private var addressAutocompleteCard: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    addressAutocomplete.clear()
                    goBack()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(.cyan)
                    .font(.subheadline.bold())
                }

                Spacer()
            }

            VStack(spacing: 10) {
                Text("What’s your address?")
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text("We’ll use this to personalize nearby communities and local services.")
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .font(.subheadline)

                    Text("* Optional")
                    .foregroundStyle(.yellow)
                    .font(.subheadline.bold())
                }
            }

            TextField(
                "Start typing your address",
                text: $address
            )
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
                .stroke(
                    .cyan.opacity(0.65),
                    lineWidth: 1.5
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .keyboardType(.default)
            .textInputAutocapitalization(.words)
            .textContentType(.fullStreetAddress)
            .autocorrectionDisabled()
            .focused(
                $focusedField,
                equals: .address
            )
            .onChange(of: address) { newValue in
                guard !isSelectingAddress else {
                    return
                }

                addressAutocomplete.updateQuery(newValue)
            }

            if !addressAutocomplete.errorMessage.isEmpty {
                Text("Address suggestions are temporarily unavailable. You can still enter your address manually.")
                .foregroundStyle(.orange)
                .font(.caption)
                .multilineTextAlignment(.center)
            }

            if !addressAutocomplete.suggestions.isEmpty {
                addressSuggestionsList
            }

            primaryButton(
                title: "Next",
                disabled: false
            ) {
                continueFromAddress()
            }

            Button {
                skipAddress()
            } label: {
                Text("Skip for Now")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white.opacity(0.08))
                .foregroundStyle(.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
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
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                focusedField = .address
            }
        }
    }

// MARK: - Signup Steps

private enum SignupStep: Equatable {
    case welcomeChoice
    case firstName
    case lastName
    case phone
    case verifyPhone
    case address
    case inviteCode

    var id: String {
        switch self {
        case .welcomeChoice:
            return "welcomeChoice"

        case .firstName:
            return "firstName"

        case .lastName:
            return "lastName"

        case .phone:
            return "phone"

        case .verifyPhone:
            return "verifyPhone"

        case .address:
            return "address"

        case .inviteCode:
            return "inviteCode"
        }
    }

    var showsProgress: Bool {
        self != .welcomeChoice
    }

    var canGoBack: Bool {
        self != .welcomeChoice
    }
}

private enum SignupField: Hashable {
    case firstName
    case lastName
    case phone
    case verificationCode
    case address
    case inviteCode
}

// MARK: - API Models

struct VerificationResponse: Codable {
    let success: Bool?
    let verified: Bool?
    let status: String?
    let phone: String?
    let message: String?
    let error: String?
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