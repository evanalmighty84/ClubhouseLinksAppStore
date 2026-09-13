import SwiftUI

struct SupportResidentPickerView: View {

    @Environment(\.dismiss)
    private var dismiss

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("supportResidentMode")
    private var supportResidentMode = false

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentFirstName")
    private var firstName = ""

    @AppStorage("residentLastName")
    private var lastName = ""

    @AppStorage("residentPhone")
    private var phone = ""

    @AppStorage("residentAddress")
    private var address = ""

    @AppStorage("residentNeighborhoodId")
    private var neighborhoodId = 0

    @AppStorage("residentNeighborhoodName")
    private var neighborhoodName = ""

    @State private var searchText = ""
    @State private var residents: [SupportResident] = []

    @State private var isSearching = false
    @State private var switchingResidentId: Int?
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            NeonBackground {
                VStack(spacing: 18) {

                    Text("Support Mode")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    Text(
                        "Search for the resident account you want to troubleshoot."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.7)
                    )
                    .multilineTextAlignment(.center)

                    HStack(spacing: 10) {

                        TextField(
                            "Name, phone, address or ID",
                            text: $searchText
                        )
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await search()
                            }
                        }

                        Button {
                            Task {
                                await search()
                            }
                        } label: {
                            Image(
                                systemName:
                                "magnifyingglass"
                            )
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.cyan)
                            .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(
                        .white.opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )

                    if isSearching {
                        ProgressView(
                            "Searching residents..."
                        )
                        .tint(.cyan)
                        .foregroundStyle(.white)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(
                            .center
                        )
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(residents) {
                                resident in

                                residentRow(resident)
                            }
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
    }

    private func residentRow(
    _ resident: SupportResident
    ) -> some View {

        Button {
            Task {
                await switchToResident(
                    resident
                )
            }
        } label: {

            HStack(spacing: 14) {

                Image(
                    systemName:
                    "person.crop.circle.fill"
                )
                .font(.system(size: 38))
                .foregroundStyle(.cyan)

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(resident.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                    if let address =
                    resident.address,
                    !address.isEmpty {

                        Text(address)
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.68)
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                    }

                    if let phone =
                    resident.phone,
                    !phone.isEmpty {

                        Text(phone)
                        .font(.caption2)
                        .foregroundStyle(
                            .cyan.opacity(0.9)
                        )
                    }

                    Text(
                        "Resident ID: \(resident.id)"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .white.opacity(0.45)
                    )
                }

                Spacer()

                if switchingResidentId ==
                resident.id {

                    ProgressView()
                    .tint(.cyan)

                } else {

                    Image(
                        systemName:
                        "chevron.right"
                    )
                    .foregroundStyle(
                        .white.opacity(0.5)
                    )
                }
            }
            .padding()
            .background(
                .white.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(
            switchingResidentId != nil
        )
    }

    @MainActor
    private func search() async {

        let term =
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard term.count >= 2 else {
            residents = []
            errorMessage =
            "Enter at least 2 characters."
            return
        }

        isSearching = true
        errorMessage = ""

        defer {
            isSearching = false
        }

        do {
            residents =
            try await
            SupportResidentAPI.shared
            .searchResidents(
                vendorId: vendorId,
                search: term
            )

            if residents.isEmpty {
                errorMessage =
                "No residents matched that search."
            }

        } catch {
            residents = []
            errorMessage =
            error.localizedDescription
        }
    }

    @MainActor
    private func switchToResident(
    _ selectedResident: SupportResident
    ) async {

        switchingResidentId =
        selectedResident.id

        errorMessage = ""

        defer {
            switchingResidentId = nil
        }

        do {
            let resident =
            try await
            SupportResidentAPI.shared
            .switchResident(
                vendorId: vendorId,
                residentId:
                selectedResident.id
            )

            /*
             * IMPORTANT:
             *
             * We do NOT change accountType or vendorId.
             * Aspen remains the signed-in vendor.
             *
             * These resident values are temporary local
             * support-view values.
             */
            residentId = resident.id
            firstName =
            resident.first_name ?? ""
            lastName =
            resident.last_name ?? ""
            phone =
            resident.phone ?? ""
            address =
            resident.address ?? ""

            neighborhoodId =
            resident.neighborhood_id ?? 0

            neighborhoodName =
            resident.neighborhood_name ?? ""

            supportResidentMode = true

            dismiss()

        } catch {
            errorMessage =
            error.localizedDescription
        }
    }
}