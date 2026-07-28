import SwiftUI

struct VendorRequestsView: View {
    @AppStorage("vendorId") private var vendorId = 0
    @AppStorage("vendorCompanyName")
    private var vendorCompanyName = ""

    @State private var requests: [VendorServiceRequest] = []
    @State private var newCount = 0
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedRequest:
        VendorServiceRequest?

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if isLoading && requests.isEmpty {
                        loadingCard
                    } else if !errorMessage.isEmpty &&
                                requests.isEmpty {
                        errorCard
                    } else if requests.isEmpty {
                        emptyCard
                    } else {
                        requestList
                    }

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .refreshable {
                await loadRequests()
            }
        }
        .task {
            VendorPushRegistration.syncStoredToken()
            await loadRequests()
            openRequestedNotificationIfNeeded()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .vendorServiceRequestReceived
            )
        ) { _ in
            Task {
                await loadRequests()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .vendorServiceRequestNotificationTapped
            )
        ) { _ in
            Task {
                await loadRequests()
                openRequestedNotificationIfNeeded()
            }
        }
        .sheet(item: $selectedRequest) { request in
            NavigationStack {
                VendorRequestDetailView(
                    request: request,
                    vendorId: vendorId
                ) {
                    Task {
                        await loadRequests()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Service Requests")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text(
                        vendorCompanyName.isEmpty
                            ? "Vendor Inbox"
                            : vendorCompanyName
                    )
                    .font(.headline)
                    .foregroundStyle(.cyan)
                }

                Spacer()

                if newCount > 0 {
                    Text("\(newCount) New")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.cyan)
                        .clipShape(Capsule())
                }
            }

            Text(
                "Open a request to see the resident’s details and update its status."
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
            .lineSpacing(3)
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.cyan)

            Text("Loading service requests...")
                .foregroundStyle(.white.opacity(0.78))
        }
        .vendorInboxCard()
    }

    private var errorCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(errorMessage)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadRequests()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .frame(maxWidth: .infinity)
        .vendorInboxCard()
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.cyan)

            Text("No service requests yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(
                "New resident requests will appear here automatically."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .vendorInboxCard()
    }

    private var requestList: some View {
        LazyVStack(spacing: 14) {
            ForEach(requests) { request in
                Button {
                    selectedRequest = request
                } label: {
                    requestCard(request)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func requestCard(
        _ request: VendorServiceRequest
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(request.serviceDisplayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(request.residentDisplayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.cyan)
                }

                Spacer()

                statusBadge(request.status)
            }

            Text(request.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack {
                if let createdAt = request.created_at {
                    Label(
                        Self.formattedDate(createdAt),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.cyan)
            }
        }
        .vendorInboxCard(
            emphasized:
                request.status.lowercased() == "new"
        )
    }

    private func statusBadge(_ status: String) -> some View {
        let cleanStatus = status.lowercased()

        return Text(cleanStatus.capitalized)
            .font(.caption.bold())
            .foregroundStyle(
                cleanStatus == "new"
                    ? Color.black
                    : Color.white
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                cleanStatus == "new"
                    ? Color.cyan
                    : Color.white.opacity(0.12)
            )
            .clipShape(Capsule())
    }

    @MainActor
    @MainActor
    private func loadRequests() async {
        guard vendorId > 0 else {
            errorMessage = "Vendor account not found."
            return
        }

        // Prevent the automatic load and pull-to-refresh
        // from running at the same time.
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = ""

        defer {
            isLoading = false
        }

        do {
            let response =
            try await VendorAPI.shared.fetchRequests(
                vendorId: vendorId
            )

            guard !Task.isCancelled else {
                return
            }

            requests = response.requests ?? []
            newCount = response.new_count ?? 0

        } catch is CancellationError {
            // SwiftUI cancelled the task because another load started.
            // Do not show this as an error to the vendor.
            return

        } catch let error as URLError
        where error.code == .cancelled {
            // URLSession cancellation is also safe to ignore.
            return

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func openRequestedNotificationIfNeeded() {
        let defaults = UserDefaults.standard

        guard let requestId = defaults.string(
            forKey: "vendorOpenRequestId"
        ),
        !requestId.isEmpty else {
            return
        }

        guard let request = requests.first(
            where: { $0.id == requestId }
        ) else {
            return
        }

        defaults.removeObject(
            forKey: "vendorOpenRequestId"
        )

        selectedRequest = request
    }

    private static func formattedDate(
        _ value: String
    ) -> String {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let standardFormatter = ISO8601DateFormatter()

        let date =
            fractionalFormatter.date(from: value) ??
            standardFormatter.date(from: value)

        guard let date else {
            return value
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short

        return displayFormatter.string(from: date)
    }
}

struct VendorRequestDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let vendorId: Int
    let onChanged: () -> Void

    @State private var request: VendorServiceRequest
    @State private var isUpdating = false
    @State private var errorMessage = ""

    init(
        request: VendorServiceRequest,
        vendorId: Int,
        onChanged: @escaping () -> Void
    ) {
        self.vendorId = vendorId
        self.onChanged = onChanged
        _request = State(initialValue: request)
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    detailHeader
                    residentCard
                    requestCard
                    actionButtons

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer(minLength: 80)
                }
                .padding()
            }
        }
        .navigationTitle("Request #\(request.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .navigationBarTrailing
            ) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await markViewedIfNeeded()
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(request.serviceDisplayName)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text(request.status.capitalized)
                .font(.caption.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.cyan)
                .clipShape(Capsule())
        }
    }

    private var residentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resident")
                .font(.title3.bold())
                .foregroundStyle(.cyan)

            Text(request.residentDisplayName)
                .font(.headline)
                .foregroundStyle(.white)

            if let phone = clean(request.resident_phone) {
                Link(
                    destination: URL(
                        string:
                            "tel:\(phone.filter(\.isNumber))"
                    )!
                ) {
                    Label(
                        formattedPhone(phone),
                        systemImage: "phone.fill"
                    )
                }
                .foregroundStyle(.cyan)
            }

            if let address = clean(
                request.resident_address
            ) {
                Label(
                    address,
                    systemImage: "mappin.and.ellipse"
                )
                .foregroundStyle(.white.opacity(0.8))
            }
        }
        .vendorInboxCard()
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request")
                .font(.title3.bold())
                .foregroundStyle(.cyan)

            detailRow(
                title: "Service",
                value: request.service
            )

            if let subService = clean(
                request.sub_service
            ) {
                detailRow(
                    title: "Sub-service",
                    value: subService
                )
            }

            Text("Message")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.58))

            Text(request.message)
                .foregroundStyle(.white)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .vendorInboxCard()
    }

    @ViewBuilder
    private var actionButtons: some View {
        let status = request.status.lowercased()

        if status == "new" || status == "viewed" {
            VStack(spacing: 12) {
                statusButton(
                    title: "Accept Request",
                    icon: "checkmark.circle.fill",
                    status: "accepted"
                )

                statusButton(
                    title: "Decline Request",
                    icon: "xmark.circle.fill",
                    status: "declined",
                    secondary: true
                )
            }
        } else if status == "accepted" {
            statusButton(
                title: "Mark Completed",
                icon: "checkmark.seal.fill",
                status: "completed"
            )
        } else {
            Text(
                status == "completed"
                    ? "This request is complete."
                    : "No additional action is required."
            )
            .font(.headline)
            .foregroundStyle(.white.opacity(0.72))
            .frame(maxWidth: .infinity)
            .vendorInboxCard()
        }
    }

    private func detailRow(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.58))

            Text(value)
                .foregroundStyle(.white)
        }
    }

    private func statusButton(
        title: String,
        icon: String,
        status: String,
        secondary: Bool = false
    ) -> some View {
        Button {
            Task {
                await updateStatus(status)
            }
        } label: {
            HStack {
                if isUpdating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                }

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                secondary
                    ? Color.white.opacity(0.10)
                    : Color.cyan.opacity(0.78)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        secondary
                            ? Color.white.opacity(0.2)
                            : Color.cyan,
                        lineWidth: 1
                    )
            )
        }
        .disabled(isUpdating)
        .opacity(isUpdating ? 0.65 : 1)
    }

    @MainActor
    private func markViewedIfNeeded() async {
        guard request.status.lowercased() == "new" else {
            return
        }

        do {
            _ = try await VendorAPI.shared.markViewed(
                vendorId: vendorId,
                requestId: request.id
            )

            request = request.replacingStatus("viewed")
            onChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func updateStatus(
        _ status: String
    ) async {
        guard !isUpdating else {
            return
        }

        isUpdating = true
        errorMessage = ""

        do {
            _ = try await VendorAPI.shared.updateStatus(
                vendorId: vendorId,
                requestId: request.id,
                status: status
            )

            request = request.replacingStatus(status)
            onChanged()
        } catch {
            errorMessage = error.localizedDescription
        }

        isUpdating = false
    }

    private func clean(
        _ value: String?
    ) -> String? {
        let cleanValue = (value ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleanValue.isEmpty
            ? nil
            : cleanValue
    }

    private func formattedPhone(
        _ value: String
    ) -> String {
        var digits = value.filter(\.isNumber)

        if digits.count == 11 &&
            digits.hasPrefix("1") {
            digits.removeFirst()
        }

        guard digits.count == 10 else {
            return value
        }

        return
            "(\(digits.prefix(3))) " +
            "\(digits.dropFirst(3).prefix(3))-" +
            "\(digits.suffix(4))"
    }
}

private extension View {
    func vendorInboxCard(
        emphasized: Bool = false
    ) -> some View {
        self
            .padding(18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                LinearGradient(
                    colors: emphasized
                        ? [
                            .cyan.opacity(0.20),
                            .purple.opacity(0.26)
                        ]
                        : [
                            .cyan.opacity(0.10),
                            .purple.opacity(0.20)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        emphasized
                            ? Color.cyan.opacity(0.85)
                            : Color.cyan.opacity(0.35),
                        lineWidth:
                            emphasized ? 1.5 : 1
                    )
            )
    }
}
