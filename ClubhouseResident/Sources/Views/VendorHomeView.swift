import SwiftUI

struct VendorHomeView: View {
    // MARK: - Stored Vendor Account

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("vendorCompanyName")
    private var storedCompanyName = ""

    @AppStorage("vendorCategory")
    private var storedCategory = ""

    @AppStorage("vendorLogoURL")
    private var storedLogoURL = ""

    // MARK: - Profile State

    @State private var vendor: VendorAccount?

    @State private var isLoadingProfile = false
    @State private var profileErrorMessage = ""

    // MARK: - Service Request State

    @State private var newRequestCount = 0
    @State private var isLoadingRequests = false

    // MARK: - Computed Display Values

    private var companyName: String {
        let profileName = vendor?.company_name
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileName.isEmpty {
            return profileName
        }

        let storedName = storedCompanyName
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return storedName.isEmpty
        ? "Vendor Account"
        : storedName
    }

    private var categoryName: String {
        let profileCategory = vendor?.category?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileCategory.isEmpty {
            return profileCategory
        }

        return storedCategory
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var logoURLString: String? {
        let profileLogo = vendor?.logo_url?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileLogo.isEmpty {
            return profileLogo
        }

        let storedLogo = storedLogoURL
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return storedLogo.isEmpty
        ? nil
        : storedLogo
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            NeonBackground {
                ScrollView {
                    VStack(spacing: 24) {
                        header

                        vendorLogoCard

                        /*
                         * This is the same transition used by the
                         * regular resident-facing HomeView:
                         *
                         * clubhouse_app_icon -> hoa
                         */
                        HomeIntroImageView()
                        .frame(height: 250)

                        clubhouseDescription

                        requestInboxCard
                    }
                    .padding()
                    .padding(.bottom, 175)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await refreshVendorHome()
                }
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
        }
        .task(id: vendorId) {
            await refreshVendorHome()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()

                NavigationLink {
                    AccountSettingsView()
                } label: {
                    accountSettingsButton
                }
                .buttonStyle(.plain)
            }

            Text(companyName.uppercased())
            .font(.largeTitle.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.58)
            .frame(maxWidth: .infinity)

            if !categoryName.isEmpty {
                Text(categoryName)
                .font(.title3.bold())
                .foregroundStyle(.cyan)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }

            if isLoadingProfile {
                ProgressView()
                .tint(.cyan)
            }

            if !profileErrorMessage.isEmpty {
                Text(profileErrorMessage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var accountSettingsButton: some View {
        HStack(spacing: 8) {
            Image(
                systemName: "gearshape.fill"
            )

            Text("Account Settings")
        }
        .font(.subheadline.bold())
        .foregroundStyle(.cyan)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            .white.opacity(0.09)
        )
        .clipShape(Capsule())
        .overlay {
            Capsule()
            .stroke(
                .cyan.opacity(0.42),
                lineWidth: 1
            )
        }
    }

    // MARK: - Vendor Logo

    private var vendorLogoCard: some View {
        VStack(spacing: 14) {
            if let logoURLString,
            let logoURL = URL(
                string: logoURLString
            ) {
                uploadedVendorLogo(
                    url: logoURL
                )
            } else {
                missingVendorLogo
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.14),
                    .purple.opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.3
            )
        }
        .shadow(
            color: .cyan.opacity(0.18),
            radius: 12
        )
    }

    private func uploadedVendorLogo(
    url: URL
    ) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                .tint(.cyan)
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            case .success(let image):
                image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(18)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(
                    .white.opacity(0.96)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )

            case .failure:
                vendorLogoLoadFailure

            @unknown default:
                vendorLogoLoadFailure
            }
        }
    }

    private var vendorLogoLoadFailure: some View {
        VStack(spacing: 14) {
            Image(
                systemName:
                "photo.badge.exclamationmark"
            )
            .font(.system(size: 48))
            .foregroundStyle(.orange)

            Text("Company Logo Unavailable")
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text(
                "Open Account Settings to upload " +
                "or replace your company logo."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(.center)

            NavigationLink {
                AccountSettingsView()
            } label: {
                settingsLogoButton
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
    }

    private var missingVendorLogo: some View {
        VStack(spacing: 14) {
            Image(
                systemName: "photo.badge.plus"
            )
            .font(.system(size: 50))
            .foregroundStyle(.cyan)

            Text("Add Your Company Logo")
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text(
                "Upload your company logo from Account " +
                "Settings so residents can recognize " +
                "your business."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            NavigationLink {
                AccountSettingsView()
            } label: {
                settingsLogoButton
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
    }

    private var settingsLogoButton: some View {
        Label(
            "Open Account Settings",
            systemImage: "gearshape.fill"
        )
        .font(.headline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    .cyan,
                    .purple
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }

    // MARK: - Clubhouse Description

    private var clubhouseDescription: some View {
        VStack(spacing: 7) {
            Text("Clubhouse Links")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            Text("Home Services")
            .font(.title2.bold())
            .foregroundStyle(.cyan)

            Text(
                "Connecting your business with homeowners, " +
                "completed projects, neighborhood events, " +
                "and new service opportunities."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Request Inbox

    private var requestInboxCard: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                Image(
                    systemName: "bell.badge.fill"
                )
                .font(.system(size: 58))
                .foregroundStyle(.cyan)

                if newRequestCount > 0 {
                    Text(
                        newRequestCount > 99
                        ? "99+"
                        : "\(newRequestCount)"
                    )
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.red)
                    .clipShape(Capsule())
                    .offset(
                        x: 14,
                        y: -7
                    )
                }
            }

            Text("Resident Service Requests")
            .font(.title2.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)

            if isLoadingRequests {
                ProgressView()
                .tint(.cyan)
            } else if newRequestCount > 0 {
                Text(
                    newRequestCount == 1
                    ? "You have 1 new request."
                    : "You have \(newRequestCount) new requests."
                )
                .font(.headline.bold())
                .foregroundStyle(.cyan)
            } else {
                Text(
                    "New requests from residents and " +
                    "FamilyTreeNow leads will appear " +
                    "in your request inbox."
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.70)
                )
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            NavigationLink {
                VendorRequestsView()
            } label: {
                HStack(spacing: 10) {
                    Image(
                        systemName: "tray.full.fill"
                    )

                    Text("Open Request Inbox")

                    if newRequestCount > 0 {
                        Spacer()

                        Text(
                            "\(newRequestCount) New"
                        )
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            .white.opacity(0.20)
                        )
                        .clipShape(Capsule())
                    }
                }
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [
                            .cyan,
                            .purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.13),
                    .purple.opacity(0.23)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                .cyan.opacity(0.54),
                lineWidth: 1.2
            )
        }
    }

    // MARK: - Refresh

    @MainActor
    private func refreshVendorHome() async {
        await loadVendorProfile()
        await loadRequestCount()
    }

    // MARK: - Vendor Profile

    @MainActor
    private func loadVendorProfile() async {
        guard vendorId > 0 else {
            profileErrorMessage =
            "Vendor account not found."
            return
        }

        guard !isLoadingProfile else {
            return
        }

        isLoadingProfile = true
        profileErrorMessage = ""

        defer {
            isLoadingProfile = false
        }

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/profile"

        guard let url = URL(
            string: urlString
        ) else {
            profileErrorMessage =
            "Invalid vendor profile URL."
            return
        }

        var request = URLRequest(url: url)

        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "no-cache",
            forHTTPHeaderField:
            "Cache-Control"
        )

        do {
            let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse =
            response as? HTTPURLResponse else {
                profileErrorMessage =
                "Invalid response from server."
                return
            }

            let decoded =
            try JSONDecoder().decode(
                VendorProfileResponse.self,
                from: data
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ),
            decoded.success == true,
            let loadedVendor =
            decoded.vendor else {
                profileErrorMessage =
                decoded.error ??
                "Could not load vendor profile."

                return
            }

            vendor = loadedVendor

            saveVendorLocally(
                loadedVendor
            )
        } catch is CancellationError {
            return
        } catch let error as URLError
        where error.code == .cancelled {
            return
        } catch {
            profileErrorMessage =
            error.localizedDescription
        }
    }

    // MARK: - Request Count

    @MainActor
    private func loadRequestCount() async {
        guard vendorId > 0 else {
            newRequestCount = 0
            return
        }

        guard !isLoadingRequests else {
            return
        }

        isLoadingRequests = true

        defer {
            isLoadingRequests = false
        }

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/service-requests" +
        "?limit=1&offset=0"

        guard let url = URL(
            string: urlString
        ) else {
            return
        }

        var request = URLRequest(url: url)

        request.cachePolicy =
        .reloadIgnoringLocalCacheData

        request.setValue(
            "no-cache",
            forHTTPHeaderField:
            "Cache-Control"
        )

        do {
            let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse =
            response as? HTTPURLResponse,
            (200...299).contains(
                httpResponse.statusCode
            ) else {
                return
            }

            let decoded =
            try JSONDecoder().decode(
                VendorRequestsResponse.self,
                from: data
            )

            guard decoded.success == true else {
                return
            }

            newRequestCount =
            decoded.new_count ?? 0
        } catch is CancellationError {
            return
        } catch let error as URLError
        where error.code == .cancelled {
            return
        } catch {
            print(
                "Vendor request count error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Local Vendor Storage

    private func saveVendorLocally(
    _ vendor: VendorAccount
    ) {
        storedCompanyName =
        vendor.company_name

        storedCategory =
        vendor.category ?? ""

        storedLogoURL =
        vendor.logo_url ?? ""
    }
}