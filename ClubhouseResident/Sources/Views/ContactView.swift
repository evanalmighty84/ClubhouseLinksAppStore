import SwiftUI

struct ContactView: View {
    @AppStorage("accountType")
    private var accountType = ""

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentFirstName")
    private var firstName = ""

    @AppStorage("residentLastName")
    private var lastName = ""

    @AppStorage("residentPhone")
    private var phone = ""

    @AppStorage("residentSelectedTab")
    private var selectedTab = "home"

    @State private var selectedService = "Painting"
    @State private var selectedVendorId = 0
    @State private var message = ""

    @State private var vendorOptions: [Vendor] = []
    @State private var vendorOptionsLoading = false
    @State private var vendorOptionsError = ""
    @State private var submitMessage = ""
    @State private var isSubmitting = false

    private let fallbackServiceOptions = [
        "Painting",
        "Pool Service",
        "Roofing",
        "Realtor",
        "Plumbing",
        "Electrical",
        "Landscaping",
        "General Contractor"
    ]

    private var isVendorAccount: Bool {
        accountType.lowercased() == "vendor" &&
        vendorId > 0
    }

    private var serviceOptions: [String] {
        let vendorCategories = vendorOptions
        .compactMap {
            $0.category?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
        .filter { !$0.isEmpty }

        return Array(
            Set(
                vendorCategories +
                fallbackServiceOptions
            )
        )
        .sorted()
    }

    private var filteredVendorOptions: [Vendor] {
        let cleanService = selectedService
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased()

        return vendorOptions.filter { vendor in
            let cleanCategory =
            (vendor.category ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

            return cleanCategory == cleanService
        }
    }

    var body: some View {
        Group {
            if isVendorAccount {
                VendorRequestsView()
            } else {
                residentContactView
            }
        }
    }

    private var residentContactView: some View {
        NeonBackground {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    Text("Contact")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    NeonCard(
                        title: "Need Help?",
                        text:
                        "Select a service, choose a vendor, and send your request directly to that vendor."
                    )

                    helpFormCard

                    Link(
                        "Call Clubhouse Links",
                        destination: URL(
                            string: "tel:2145489175"
                        )!
                    )
                    .font(.headline)
                    .foregroundStyle(.cyan)

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .scrollDismissesKeyboard(
                .interactively
            )
        }
        .onAppear {
            loadVendorOptions()
        }
        .onChange(of: selectedService) { _ in
            selectFirstVendorForService()
        }
        .onChange(of: selectedVendorId) { _ in
            syncServiceToSelectedVendor()
        }
    }

    private var helpFormCard: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            Text("Request a Service")
            .font(.title2.bold())
            .foregroundStyle(.white)

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker(
                    "Service",
                    selection: $selectedService
                ) {
                    ForEach(
                        serviceOptions,
                        id: \.self
                    ) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Vendor")
                .font(.headline)
                .foregroundStyle(.cyan)

                if vendorOptionsLoading {
                    ProgressView()
                    .tint(.cyan)
                    .padding(.vertical, 12)
                } else if !vendorOptionsError.isEmpty {
                    Text(vendorOptionsError)
                    .font(.caption)
                    .foregroundStyle(
                        .red.opacity(0.9)
                    )
                } else if filteredVendorOptions.isEmpty {
                    Text(
                        "No vendors found for this service."
                    )
                    .font(.caption.bold())
                    .foregroundStyle(
                        .white.opacity(0.65)
                    )
                } else {
                    Picker(
                        "Vendor",
                        selection: $selectedVendorId
                    ) {
                        ForEach(
                            filteredVendorOptions
                        ) { vendor in
                            Text(vendor.company_name)
                            .tag(vendor.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        .black.opacity(0.22)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Message")
                .font(.headline)
                .foregroundStyle(.cyan)

                TextField(
                    "Describe what you need",
                    text: $message,
                    axis: .vertical
                )
                .lineLimit(4...7)
                .padding()
                .foregroundStyle(.white)
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                    .stroke(
                        .cyan.opacity(0.5),
                        lineWidth: 1
                    )
                )
            }

            Button {
                submitHelpRequest()
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                        .tint(.white)
                    }

                    Text(
                        isSubmitting
                        ? "Sending..."
                        : "Submit"
                    )
                    .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            .purple,
                            .orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .shadow(
                    color: .cyan.opacity(0.35),
                    radius: 10
                )
            }
            .disabled(
                isSubmitting ||
                vendorOptionsLoading
            )
            .opacity(
                isSubmitting ||
                vendorOptionsLoading
                ? 0.65
                : 1
            )

            if !submitMessage.isEmpty {
                Text(submitMessage)
                .font(.subheadline.bold())
                .foregroundStyle(
                    submitMessage
                    .lowercased()
                    .contains("sent")
                    ? .cyan
                    : .red
                )
                .multilineTextAlignment(
                    .center
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.13),
                    .purple.opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.55),
                lineWidth: 1
            )
        )
    }

    private func loadVendorOptions() {
        guard residentId > 0 else {
            vendorOptionsError =
            "Resident profile not found."
            return
        }

        vendorOptionsLoading = true
        vendorOptionsError = ""

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/vendors/\(residentId)"

        guard let url = URL(
            string: urlString
        ) else {
            vendorOptionsLoading = false
            vendorOptionsError =
            "Invalid vendor URL."
            return
        }

        URLSession.shared.dataTask(
            with: url
        ) { data, _, error in
            DispatchQueue.main.async {
                vendorOptionsLoading = false

                if let error {
                    vendorOptionsError =
                    error.localizedDescription
                    return
                }

                guard let data else {
                    vendorOptionsError =
                    "No vendors found."
                    return
                }

                do {
                    let decoded =
                    try JSONDecoder().decode(
                        VendorResponse.self,
                        from: data
                    )

                    guard decoded.success == true else {
                        vendorOptionsError =
                        decoded.error ??
                        "Could not load vendors."
                        return
                    }

                    vendorOptions =
                    decoded.vendors ?? []

                    if let firstVendor =
                    vendorOptions.first {
                        selectedVendorId =
                        firstVendor.id
                        selectedService =
                        firstVendor.category ??
                        selectedService
                    }
                } catch {
                    vendorOptionsError =
                    String(
                        data: data,
                        encoding: .utf8
                    ) ??
                    "Could not decode vendors."
                }
            }
        }
        .resume()
    }

    private func selectFirstVendorForService() {
        guard let firstVendor =
        filteredVendorOptions.first else {
            selectedVendorId = 0
            return
        }

        if !filteredVendorOptions.contains(
            where: {
                $0.id == selectedVendorId
            }
        ) {
            selectedVendorId =
            firstVendor.id
        }
    }

    private func syncServiceToSelectedVendor() {
        guard let vendor =
        selectedVendor() else {
            return
        }

        if let category = vendor.category,
        !category.isEmpty {
            selectedService = category
        }
    }

    private func selectedVendor() -> Vendor? {
        vendorOptions.first {
            $0.id == selectedVendorId
        }
    }

    private func submitHelpRequest() {
        guard !isSubmitting else {
            return
        }

        let cleanMessage =
        message.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard residentId > 0 else {
            submitMessage =
            "Resident profile not found."
            return
        }

        guard selectedVendorId > 0 else {
            submitMessage =
            "Please select a vendor."
            return
        }

        guard !cleanMessage.isEmpty else {
            submitMessage =
            "Please enter a message."
            return
        }

        let payload =
        ResidentServiceRequestPayload(
            vendor_id: selectedVendorId,
            service: selectedService,
            sub_service: nil,
            message: cleanMessage
        )

        isSubmitting = true
        submitMessage = ""

        Task {
            do {
                let response =
                try await VendorAPI.shared
                .submitResidentRequest(
                    residentId: residentId,
                    payload: payload
                )

                await MainActor.run {
                    let vendorName =
                    selectedVendor()?
                    .company_name ??
                    "the selected vendor"

                    submitMessage =
                    response.message ??
                    "Your request was sent to \(vendorName)."

                    message = ""
                    isSubmitting = false

                    DispatchQueue.main
                    .asyncAfter(
                        deadline:
                        .now() + 1.0
                    ) {
                        selectedTab = "home"
                    }
                }
            } catch {
                await MainActor.run {
                    submitMessage =
                    error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}
