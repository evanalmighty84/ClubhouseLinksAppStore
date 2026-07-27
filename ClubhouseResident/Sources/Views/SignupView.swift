import SwiftUI
import MapKit

// MARK: - Apple Maps Address Autocomplete

final class AddressAutocomplete:
NSObject,
ObservableObject,
MKLocalSearchCompleterDelegate {

    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var errorMessage = ""

    private let completer = MKLocalSearchCompleter()
    private var acceptsDelegateUpdates = false

    override init() {
        super.init()

        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Immediately remove an old autocomplete error
        // when the user starts typing again.
        errorMessage = ""

        guard trimmedQuery.count >= 3 else {
            acceptsDelegateUpdates = false
            completer.queryFragment = ""
            suggestions = []
            return
        }

        acceptsDelegateUpdates = true
        completer.queryFragment = trimmedQuery
    }

    func clear() {
        // Ignore any delayed callback from the previous search.
        acceptsDelegateUpdates = false
        completer.queryFragment = ""
        suggestions = []
        errorMessage = ""
    }

    func completerDidUpdateResults(
    _ completer: MKLocalSearchCompleter
    ) {
        guard acceptsDelegateUpdates else {
            return
        }

        DispatchQueue.main.async {
            guard self.acceptsDelegateUpdates else {
                return
            }

            self.suggestions = Array(
                completer.results.prefix(5)
            )

            self.errorMessage = ""
        }
    }

    func completer(
    _ completer: MKLocalSearchCompleter,
    didFailWithError error: Error
    ) {
        guard acceptsDelegateUpdates else {
            return
        }

        DispatchQueue.main.async {
            guard self.acceptsDelegateUpdates else {
                return
            }

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
                question: "What’s your invite code?",
                subtitle: "Enter the code from your community, contractor, or local service provider.",
                placeholder: "Invite Code",
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

        return "Create Account"
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
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .textContentType(.oneTimeCode)
            .autocorrectionDisabled()
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
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused(
                $focusedField,
                equals: .verificationCode
            )
            .onChange(of: verificationCode) { newValue in
                let cleanedCode = String(
                    newValue
                    .filter(\.isNumber)
                    .prefix(6)
                )

                if verificationCode != cleanedCode {
                    verificationCode = cleanedCode
                }
            }

            .labelStyle(.titleAndIcon)
            .tint(.cyan)
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

            if !addressAutocomplete.errorMessage.isEmpty &&
            addressAutocomplete.suggestions.isEmpty {

                Text(
                    "Address suggestions are temporarily unavailable. You can still enter your address manually."
                )
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

    private var addressSuggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(
                    addressAutocomplete
                    .suggestions
                    .enumerated()
                ),
                id: \.offset
            ) { index, suggestion in
                Button {
                    selectAddressSuggestion(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.cyan)

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(suggestion.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(
                                    .white.opacity(0.65)
                                )
                                .multilineTextAlignment(.leading)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                        .foregroundStyle(
                            .white.opacity(0.45)
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                }
                .buttonStyle(.plain)

                if index <
                addressAutocomplete.suggestions.count - 1 {
                    Divider()
                    .overlay(.white.opacity(0.12))
                }
            }
        }
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
            .stroke(
                .cyan.opacity(0.35),
                lineWidth: 1
            )
        )
    }

    // MARK: - Shared Components

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
            .focused(
                $focusedField,
                equals: field
            )

            primaryButton(
                title: buttonTitle,
                disabled: isPrimaryDisabled
            ) {
                hideKeyboard()
                onNext()
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
        .onAppear {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                focusedField = field
            }
        }
    }
    private func continueFromAddress() {
        let trimmedAddress = address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        address = trimmedAddress
        errorMessage = ""
        hideKeyboard()
        addressAutocomplete.clear()
        goTo(.inviteCode, focus: .inviteCode)
    }

    private func skipAddress() {
        address = ""
        errorMessage = ""
        hideKeyboard()
        addressAutocomplete.clear()
        goTo(.inviteCode, focus: .inviteCode)
    }
    private func neonTextField(
    placeholder: String,
    text: Binding<String>,
    keyboardType: UIKeyboardType
    ) -> some View {
        TextField(
            placeholder,
            text: text
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
        .keyboardType(keyboardType)
        .textInputAutocapitalization(
            keyboardType == .default
            ? .words
            : .never
        )
        .autocorrectionDisabled()
    }

    private func primaryButton(
    title: String,
    disabled: Bool,
    action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
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
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
            .shadow(
                color: .cyan.opacity(0.35),
                radius: 10
            )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }

    // MARK: - Phone Helpers

    private var normalizedPhone: String {
        let trimmedPhone = phone.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let digits = trimmedPhone.filter(\.isNumber)

        if digits.count == 10 {
            return "+1\(digits)"
        }

        if digits.count == 11 && digits.hasPrefix("1") {
            return "+\(digits)"
        }

        if trimmedPhone.hasPrefix("+") && digits.count >= 10 {
            return "+\(digits)"
        }

        return trimmedPhone
    }

    private var isValidPhoneNumber: Bool {
        let digits = phone.filter(\.isNumber)

        return digits.count == 10 ||
        (digits.count == 11 && digits.hasPrefix("1"))
    }

    private var isPhoneVerifiedForCurrentNumber: Bool {
        !verifiedPhone.isEmpty &&
        verifiedPhone == normalizedPhone
    }

    private var phoneButtonTitle: String {
        if isSendingVerification {
            return "Sending..."
        }

        if isPhoneVerifiedForCurrentNumber {
            return "Continue"
        }

        return "Send Verification Code"
    }

    private var formattedPhoneForDisplay: String {
        var digits = phone.filter(\.isNumber)

        if digits.count == 11 && digits.hasPrefix("1") {
            digits.removeFirst()
        }

        guard digits.count == 10 else {
            return phone
        }

        let areaCode = digits.prefix(3)
        let prefix = digits.dropFirst(3).prefix(3)
        let lineNumber = digits.suffix(4)

        return "(\(areaCode)) \(prefix)-\(lineNumber)"
    }

    private func handlePhoneNumberChange() {
        guard !verifiedPhone.isEmpty else {
            return
        }

        guard normalizedPhone != verifiedPhone else {
            return
        }

        verifiedPhone = ""
        verificationCode = ""
        verificationMessage = ""
    }

    // MARK: - Twilio Verification Requests

    private func sendVerificationCode(
    isResend: Bool = false
    ) {
        errorMessage = ""
        verificationMessage = ""

        guard isValidPhoneNumber else {
            errorMessage =
            "Please enter a valid 10-digit mobile phone number."
            return
        }

        guard let url = URL(string: sendVerificationURL) else {
            errorMessage = "Invalid verification URL."
            return
        }

        isSendingVerification = true
        verifiedPhone = ""
        verificationCode = ""

        let payload: [String: String] = [
            "phone": normalizedPhone
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: payload
        )

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in
            DispatchQueue.main.async {
                isSendingVerification = false

                if let error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data else {
                    errorMessage =
                    "No response from the verification server."
                    return
                }

                let decoded = try? JSONDecoder().decode(
                    VerificationResponse.self,
                    from: data
                )

                if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode) {
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "We could not send the verification code."
                    return
                }

                guard decoded?.success == true else {
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "We could not send the verification code."
                    return
                }

                verificationMessage = isResend
                ? "A new verification code was sent."
                : "Verification code sent."

                if isResend {
                    focusedField = .verificationCode
                } else {
                    goTo(
                        .verifyPhone,
                        focus: .verificationCode
                    )
                }
            }
        }
        .resume()
    }

    private func checkVerificationCode() {
        errorMessage = ""
        verificationMessage = ""

        let trimmedCode = verificationCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedCode.count == 6 else {
            errorMessage =
            "Please enter the six-digit code sent to your phone."
            return
        }

        guard let url = URL(string: checkVerificationURL) else {
            errorMessage = "Invalid verification URL."
            return
        }

        isCheckingVerification = true

        let payload: [String: String] = [
            "phone": normalizedPhone,
            "code": trimmedCode
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: payload
        )

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in
            DispatchQueue.main.async {
                isCheckingVerification = false

                if let error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data else {
                    errorMessage =
                    "No response from the verification server."
                    return
                }

                let decoded = try? JSONDecoder().decode(
                    VerificationResponse.self,
                    from: data
                )

                if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode) {
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "That verification code is incorrect or expired."
                    return
                }

                guard decoded?.success == true,
                decoded?.verified == true else {
                    verifiedPhone = ""
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "That verification code is incorrect or expired."
                    return
                }

                verifiedPhone = normalizedPhone
                verificationMessage =
                "Your mobile number has been verified."
                errorMessage = ""

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.35
                ) {
                    goTo(.address, focus: .address)
                }
            }
        }
        .resume()
    }

    // MARK: - Address Selection

    private func selectAddressSuggestion(
    _ suggestion: MKLocalSearchCompletion
    ) {
        errorMessage = ""
        hideKeyboard()

        let request = MKLocalSearch.Request(
            completion: suggestion
        )

        request.resultTypes = .address

        MKLocalSearch(request: request).start {
            response,
            error in

            DispatchQueue.main.async {
                if let error {
                    errorMessage =
                    "Unable to verify address: \(error.localizedDescription)"
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    errorMessage =
                    "Unable to find that address."
                    return
                }

                isSelectingAddress = true

                if let formattedAddress = mapItem.placemark.title,
                !formattedAddress.isEmpty {
                    address = formattedAddress
                } else {
                    address = [
                        suggestion.title,
                        suggestion.subtitle
                    ]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                }

                addressAutocomplete.clear()
                focusedField = nil
                errorMessage = ""

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.1
                ) {
                    isSelectingAddress = false
                }
            }
        }
    }

    // MARK: - Navigation

    private func goTo(
    _ step: SignupStep,
    focus: SignupField? = nil
    ) {
        hideKeyboard()

        if currentStep == .address && step != .address {
            addressAutocomplete.clear()
        }

        withAnimation(
            .easeInOut(duration: 0.4)
        ) {
            currentStep = step
        }

        if let focus {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.42
            ) {
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
            goTo(.lastName, focus: .lastName)

        case .verifyPhone:
            verificationCode = ""
            verificationMessage = ""
            goTo(.phone, focus: .phone)

        case .address:
            addressAutocomplete.clear()
            goTo(.phone, focus: .phone)

        case .inviteCode:
            goTo(.address, focus: .address)

        case .welcomeChoice:
            break
        }
    }

    // MARK: - Final Signup

    private func submitSignup() {
        errorMessage = ""

        let trimmedFirstName = firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedLastName = lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedAddress = address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedCode = neighborhoodCode
        .uppercased()
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedFirstName.isEmpty,
        !trimmedLastName.isEmpty,
        !normalizedPhone.isEmpty,
        !trimmedCode.isEmpty else {
            errorMessage = "Please enter your invite code."
            return
        }

        guard isPhoneVerifiedForCurrentNumber else {
            errorMessage =
            "Please verify your mobile number before creating your account."

            goTo(.phone, focus: .phone)
            return
        }

        guard let url = URL(string: signupURL) else {
            errorMessage = "Invalid server URL."
            return
        }

        isLoading = true

        var payload: [String: String] = [
            "first_name": trimmedFirstName,
            "last_name": trimmedLastName,
            "phone": normalizedPhone,
            "address": trimmedAddress
        ]

        if !trimmedCode.isEmpty {
            payload["invite_code"] = trimmedCode
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: payload
        )

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data else {
                    errorMessage = "No response from server."
                    return
                }

                let decoded = try? JSONDecoder().decode(
                    SignupResponse.self,
                    from: data
                )

                if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode) {
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "Signup failed."
                    return
                }

                guard decoded?.success == true,
                let resident = decoded?.resident,
                let newResidentId = decoded?.resident_id else {
                    errorMessage =
                    decoded?.error ??
                    decoded?.message ??
                    "Signup failed."
                    return
                }

                residentId = newResidentId
                savedFirstName = resident.first_name
                savedLastName = resident.last_name
                savedPhone = resident.phone
                savedAddress = trimmedAddress
                residentApprovalStatus = resident.approval_status
                residentNeighborhoodId =
                resident.neighborhood_id ?? 0
                displayAreaName =
                resident.display_area_name ?? ""
                residentNeighborhoodName =
                resident.neighborhood_name ?? ""

                residentIsSignedUp = true
                dismiss()
            }
        }
        .resume()
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