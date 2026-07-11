import SwiftUI
import MapKit

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
    @State private var address = ""
    @State private var neighborhoodCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isSelectingAddress = false

    @State private var currentStep: SignupStep = .welcomeChoice
    @FocusState private var focusedField: SignupField?

    private let signupURL =
    "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/signup"

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
                    guard !firstName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty else {
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
                subtitle: "We’ll use this to create your account.",
                placeholder: "Enter Last Name",
                text: $lastName,
                field: .lastName,
                keyboardType: .default,
                buttonTitle: "Next",
                onNext: {
                    guard !lastName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty else {
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
                subtitle: "This helps verify your account and personalize your local experience.",
                placeholder: "Enter Phone Number",
                text: $phone,
                field: .phone,
                keyboardType: .phonePad,
                buttonTitle: "Next",
                onNext: {
                    guard !phone
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty else {
                        errorMessage = "Please enter your phone number."
                        return
                    }

                    errorMessage = ""
                    goTo(.address, focus: .address)
                }
            )

        case .address:
            addressAutocompleteCard

        case .inviteCode:
            questionCard(
                question: "Do you have an invite code?",
                subtitle: "Enter a code shared by a participating community or local business.",
                placeholder: "Enter Invite Code",
                text: $neighborhoodCode,
                field: .inviteCode,
                keyboardType: .default,
                buttonTitle: isLoading
                ? "Creating..."
                : "Create Account",
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

                Text(
                    "Create your account to discover nearby communities, events, and trusted local services."
                )
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
            }

            Button {
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
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .shadow(
                    color: .cyan.opacity(0.4),
                    radius: 10
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.45),
                lineWidth: 1
            )
        )
    }

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

                Text(
                    "We’ll use this to personalize nearby communities and local services."
                )
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .font(.subheadline)
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
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
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
                Text(
                    "Address suggestions are temporarily unavailable. You can still enter your address manually."
                )
                .foregroundStyle(.orange)
                .font(.caption)
                .multilineTextAlignment(.center)
            }

            if !addressAutocomplete.suggestions.isEmpty {
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
                                Image(
                                    systemName: "mappin.and.ellipse"
                                )
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
                                        .multilineTextAlignment(
                                            .leading
                                        )
                                    }
                                }

                                Spacer()

                                Image(
                                    systemName: "chevron.right"
                                )
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
                        addressAutocomplete
                        .suggestions
                        .count - 1 {
                            Divider()
                            .overlay(
                                .white.opacity(0.12)
                            )
                        }
                    }
                }
                .background(
                    .black.opacity(0.3)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        .cyan.opacity(0.35),
                        lineWidth: 1
                    )
                )
            }

            Button {
                let trimmedAddress =
                address.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !trimmedAddress.isEmpty else {
                    errorMessage =
                    "Please select or enter your address."
                    return
                }

                address = trimmedAddress
                errorMessage = ""
                hideKeyboard()
                addressAutocomplete.clear()
                goTo(.inviteCode, focus: .inviteCode)
            } label: {
                Text("Next")
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
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.45),
                lineWidth: 1
            )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                focusedField = .address
            }
        }
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
            .focused(
                $focusedField,
                equals: field
            )

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
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .shadow(
                    color: .cyan.opacity(0.35),
                    radius: 10
                )
            }
            .disabled(isPrimaryDisabled)
            .opacity(
                isPrimaryDisabled
                ? 0.6
                : 1
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.45),
                lineWidth: 1
            )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                focusedField = field
            }
        }
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
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .keyboardType(keyboardType)
        .textInputAutocapitalization(
            keyboardType == .default
            ? .words
            : .never
        )
        .autocorrectionDisabled()
    }

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

                guard let mapItem =
                response?.mapItems.first else {
                    errorMessage =
                    "Unable to find that address."
                    return
                }

                isSelectingAddress = true

                if let formattedAddress =
                mapItem.placemark.title,
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

    private var fullDisplayName: String {
        let combined =
        "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return combined.isEmpty
        ? "Member"
        : combined
    }

    private func goTo(
    _ step: SignupStep,
    focus: SignupField? = nil
    ) {
        hideKeyboard()

        if currentStep == .address &&
        step != .address {
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
            goTo(
                .firstName,
                focus: .firstName
            )

        case .phone:
            goTo(
                .lastName,
                focus: .lastName
            )

        case .address:
            addressAutocomplete.clear()

            goTo(
                .phone,
                focus: .phone
            )

        case .inviteCode:
            goTo(
                .address,
                focus: .address
            )

        case .welcomeChoice:
            break
        }
    }

    private func submitSignup() {
        errorMessage = ""

        let trimmedFirstName =
        firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedLastName =
        lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedPhone =
        phone.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedAddress =
        address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedCode =
        neighborhoodCode
        .uppercased()
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedFirstName.isEmpty,
        !trimmedLastName.isEmpty,
        !trimmedPhone.isEmpty,
        !trimmedAddress.isEmpty,
        !trimmedCode.isEmpty else {
            errorMessage = "Please complete all fields."
            return
        }

        guard let url = URL(string: signupURL) else {
            errorMessage = "Invalid server URL."
            return
        }

        isLoading = true

        let payload: [String: String] = [
            "first_name": trimmedFirstName,
            "last_name": trimmedLastName,
            "phone": trimmedPhone,
            "address": trimmedAddress,
            "invite_code": trimmedCode
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
        ) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error {
                    errorMessage =
                    error.localizedDescription
                    return
                }

                guard let data else {
                    errorMessage =
                    "No response from server."
                    return
                }

                do {
                    let decoded =
                    try JSONDecoder().decode(
                        SignupResponse.self,
                        from: data
                    )

                    if decoded.success == true,
                    let resident = decoded.resident,
                    let newResidentId =
                    decoded.resident_id {

                        residentId = newResidentId
                        savedFirstName =
                        resident.first_name
                        savedLastName =
                        resident.last_name
                        savedPhone =
                        resident.phone
                        savedAddress =
                        trimmedAddress
                        residentApprovalStatus =
                        resident.approval_status
                        residentNeighborhoodId =
                        resident.neighborhood_id ?? 0
                        displayAreaName =
                        resident.display_area_name ?? ""
                        residentNeighborhoodName =
                        resident.neighborhood_name ?? ""

                        residentIsSignedUp = true
                        dismiss()
                    } else {
                        errorMessage =
                        decoded.error ??
                        "Signup failed."
                    }
                } catch {
                    let rawResponse =
                    String(
                        data: data,
                        encoding: .utf8
                    ) ??
                    "Unreadable response"

                    errorMessage = rawResponse
                    print(rawResponse)
                }
            }
        }
        .resume()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
            UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private enum SignupStep: Equatable {
    case welcomeChoice
    case firstName
    case lastName
    case phone
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

        case .address:
            return "address"

        case .inviteCode:
            return "inviteCode"
        }
    }

    var showsProgress: Bool {
        switch self {
        case .welcomeChoice:
            return false

        default:
            return true
        }
    }

    var canGoBack: Bool {
        switch self {
        case .welcomeChoice:
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