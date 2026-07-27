import SwiftUI
import MapKit
import UIKit

struct StartServiceView: View {
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentDisplayAreaName") private var displayAreaName = ""

    @StateObject private var addressAutocomplete = AddressAutocomplete()

    @State private var editableAddress = ""
    @State private var isSelectingAddress = false
    @State private var addressError = ""
    @State private var addressMessage = ""

    @State private var selectedService = "Painting"
    @State private var selectedSubService = "Interior Painting"

    private let services = [
        "Painting",
        "Roofing",
        "Pool Service",
        "Landscaping",
        "Plumbing",
        "Electrical",
        "Cleaning",
        "General Contractor"
    ]

    private var needsAddress: Bool {
        address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var subServices: [String] {
        switch selectedService {
        case "Painting":
            return ["Interior Painting", "Exterior Painting", "Cabinets", "Drywall Repair", "Fence Staining"]
        case "Roofing":
            return ["Roof Repair", "Roof Replacement", "Inspection", "Gutters"]
        case "Pool Service":
            return ["Weekly Service", "Pool Repair", "Leak Detection", "Equipment Replacement"]
        case "Landscaping":
            return ["Lawn Care", "Tree Trimming", "Flower Beds", "Irrigation"]
        case "Plumbing":
            return ["Leak Repair", "Water Heater", "Drain Cleaning", "Fixture Install"]
        case "Electrical":
            return ["Light Install", "Outlet Repair", "Panel Work", "Ceiling Fan"]
        case "Cleaning":
            return ["House Cleaning", "Deep Cleaning", "Move Out Cleaning", "Window Cleaning"]
        default:
            return ["General Repair", "Remodeling", "Handyman", "Project Estimate"]
        }
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if needsAddress {
                        addressStep
                    } else {
                        serviceStep
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            editableAddress = address
        }
        .onChange(of: selectedService) { _ in
            selectedSubService = subServices.first ?? ""
        }
    }

    private var addressStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What’s your address?")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            Text("Add your address first so we can show the right local vendors and nearby completed projects.")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
            .lineSpacing(4)

            VStack(spacing: 16) {
                TextField(
                    "Start typing your address",
                    text: $editableAddress
                )
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 62)
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
                    RoundedRectangle(cornerRadius: 18)
                    .stroke(.cyan.opacity(0.65), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .keyboardType(.default)
                .textInputAutocapitalization(.words)
                .textContentType(.fullStreetAddress)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    saveAddressAndContinue()
                }
                .onChange(of: editableAddress) { newValue in
                    addressError = ""
                    addressMessage = ""

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

                if !addressError.isEmpty {
                    Text(addressError)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                }

                if !addressMessage.isEmpty {
                    Text(addressMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                }

                Button {
                    saveAddressAndContinue()
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
                }
            }
            .padding(18)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                .stroke(.cyan.opacity(0.45), lineWidth: 1)
            )
        }
    }

    private var addressSuggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(addressAutocomplete.suggestions.enumerated()),
                id: \.offset
            ) { index, suggestion in
                Button {
                    selectAddressSuggestion(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.cyan)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.leading)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .buttonStyle(.plain)

                if index < addressAutocomplete.suggestions.count - 1 {
                    Divider()
                    .overlay(.white.opacity(0.12))
                }
            }
        }
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
            .stroke(.cyan.opacity(0.35), lineWidth: 1)
        )
    }

    private var serviceStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Start a Service")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            Text("Choose what you need help with and we’ll guide you to the right local vendor.")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 16) {
                AppleLookAroundCard(address: address)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Text("Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker("Service", selection: $selectedService) {
                    ForEach(services, id: \.self) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("Sub Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker("Sub Service", selection: $selectedSubService) {
                    ForEach(subServices, id: \.self) { subService in
                        Text(subService).tag(subService)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    print("Selected service:", selectedService)
                    print("Selected sub service:", selectedSubService)
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
                }
            }
            .padding(18)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                .stroke(.cyan.opacity(0.45), lineWidth: 1)
            )
        }
    }

    private func selectAddressSuggestion(
    _ suggestion: MKLocalSearchCompletion
    ) {
        addressError = ""
        addressMessage = ""
        hideKeyboard()

        let request = MKLocalSearch.Request(completion: suggestion)
        request.resultTypes = .address

        MKLocalSearch(request: request).start { response, error in
            DispatchQueue.main.async {
                if let error {
                    addressError = "Unable to verify address: \(error.localizedDescription)"
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    addressError = "Unable to find that address."
                    return
                }

                isSelectingAddress = true

                if let formattedAddress = mapItem.placemark.title,
                !formattedAddress.isEmpty {
                    editableAddress = formattedAddress
                } else {
                    editableAddress = [
                        suggestion.title,
                        suggestion.subtitle
                    ]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                }

                addressAutocomplete.clear()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSelectingAddress = false
                    saveAddressAndContinue()
                }
            }
        }
    }

    private func saveAddressAndContinue() {
        let trimmedAddress = editableAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedAddress.isEmpty else {
            addressError = "Please enter your address."
            return
        }

        address = trimmedAddress

        if let areaFromAddress = displayAreaFromAddress(trimmedAddress) {
            displayAreaName = areaFromAddress
        } else {
            displayAreaName = "Local Customer Area"
        }

        addressAutocomplete.clear()
        addressError = ""
        addressMessage = "Address saved."
        hideKeyboard()
    }

    private func displayAreaFromAddress(_ address: String) -> String? {
        let parts = address
        .split(separator: ",")
        .map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard parts.count >= 3 else {
            return nil
        }

        let city = parts[1]

        let stateZipPart = parts[2]
        .split(separator: " ")
        .map(String.init)

        guard let state = stateZipPart.first else {
            return nil
        }

        if city.isEmpty || state.isEmpty {
            return nil
        }

        return "\(city), \(state)"
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