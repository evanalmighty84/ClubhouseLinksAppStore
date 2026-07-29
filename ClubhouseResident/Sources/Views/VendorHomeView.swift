import SwiftUI
import PhotosUI
import UIKit

struct VendorHomeView: View {
    // MARK: - Stored Account Values

    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("vendorCompanyName")
    private var storedCompanyName = ""

    @AppStorage("vendorCategory")
    private var storedCategory = ""

    @AppStorage("vendorLogoURL")
    private var storedLogoURL = ""

    // Replace this with the exact asset name used in HomeView.
    private let clubhouseImageAssetName = "clubhouse"

    // MARK: - Profile State

    @State private var vendor: VendorAccount?

    @State private var isLoadingProfile = false
    @State private var profileErrorMessage = ""

    // MARK: - Request State

    @State private var newRequestCount = 0
    @State private var isLoadingRequests = false

    // MARK: - Logo State

    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var isShowingLogoPicker = false
    @State private var isUploadingLogo = false
    @State private var logoMessage = ""

    // MARK: - Computed Values

    private var companyName: String {
        let profileValue = vendor?.company_name
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileValue.isEmpty {
            return profileValue
        }

        let storedValue = storedCompanyName
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return storedValue.isEmpty
        ? "Vendor Account"
        : storedValue
    }

    private var categoryName: String {
        let profileValue = vendor?.category?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileValue.isEmpty {
            return profileValue
        }

        return storedCategory
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var logoURLString: String? {
        let profileValue = vendor?.logo_url?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileValue.isEmpty {
            return profileValue
        }

        let storedValue = storedLogoURL
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return storedValue.isEmpty
        ? nil
        : storedValue
    }

    private var logoMessageColor: Color {
        let normalized = logoMessage.lowercased()

        if normalized.contains("could not") ||
        normalized.contains("invalid") ||
        normalized.contains("too large") ||
        normalized.contains("not found") ||
        normalized.contains("failed") ||
        normalized.contains("error") {
            return .red
        }

        return .cyan
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            NeonBackground {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 22
                    ) {
                        header

                        vendorLogoCard

                        clubhousePhotoCard

                        requestInboxCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 190)
                }
                .refreshable {
                    await refreshVendorHome()
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task(id: vendorId) {
            await refreshVendorHome()
        }
        .photosPicker(
            isPresented: $isShowingLogoPicker,
            selection: $selectedLogoItem,
            matching: .images
        )
        .onChange(of: selectedLogoItem) { newItem in
            guard let newItem else {
                return
            }

            Task {
                await prepareAndUploadLogo(
                    from: newItem
                )
            }
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
            .minimumScaleFactor(0.62)
            .lineLimit(2)
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
                .foregroundStyle(.red.opacity(0.92))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var accountSettingsButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")

            Text("Account Settings")
        }
        .font(.subheadline.bold())
        .foregroundStyle(.cyan)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.09))
        .clipShape(Capsule())
        .overlay(
            Capsule()
            .stroke(
                .cyan.opacity(0.42),
                lineWidth: 1
            )
        )
    }

    // MARK: - Vendor Logo Card

    private var vendorLogoCard: some View {
        VStack(spacing: 16) {
            if let logoURLString,
            let logoURL = URL(string: logoURLString) {
                uploadedLogoContent(
                    logoURL: logoURL
                )
            } else {
                uploadLogoContent
            }

            if isUploadingLogo {
                HStack(spacing: 10) {
                    ProgressView()
                    .tint(.cyan)

                    Text("Uploading company logo...")
                    .font(.subheadline.bold())
                    .foregroundStyle(
                        .white.opacity(0.80)
                    )
                }
            }

            if !logoMessage.isEmpty {
                Text(logoMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(logoMessageColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
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
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
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
        )
        .shadow(
            color: .cyan.opacity(0.18),
            radius: 12
        )
    }

    private func uploadedLogoContent(
    logoURL: URL
    ) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: logoURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                    .tint(.cyan)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 210)

                case .success(let image):
                    image
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 210)
                    .background(
                        .white.opacity(0.95)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 22
                        )
                    )

                case .failure:
                    logoLoadFailureContent

                @unknown default:
                    logoLoadFailureContent
                }
            }

            Button {
                isShowingLogoPicker = true
            } label: {
                Label(
                    "Change Company Logo",
                    systemImage: "photo.badge.plus"
                )
                .font(.subheadline.bold())
                .foregroundStyle(.cyan)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    .black.opacity(0.22)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isUploadingLogo)
        }
    }

    private var logoLoadFailureContent: some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                "exclamationmark.triangle.fill"
            )
            .font(.system(size: 42))
            .foregroundStyle(.orange)

            Text("Could not load company logo.")
            .font(.subheadline.bold())
            .foregroundStyle(.white)

            Button("Choose Another Logo") {
                isShowingLogoPicker = true
            }
            .font(.subheadline.bold())
            .foregroundStyle(.cyan)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
    }

    private var uploadLogoContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
            .font(.system(size: 54))
            .foregroundStyle(.cyan)

            Text("Upload Company Logo")
            .font(.title2.bold())
            .foregroundStyle(.white)

            Text(
                "Add your company logo so residents " +
                "can recognize your business."
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

            Button {
                isShowingLogoPicker = true
            } label: {
                Text("Choose Logo")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 13)
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
            .buttonStyle(.plain)
            .disabled(isUploadingLogo)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 230)
    }

    // MARK: - Clubhouse Photo Card

    private var clubhousePhotoCard: some View {
        VStack(spacing: 16) {
            clubhousePhoto

            Text("Clubhouse Links")
            .font(.title2.bold())
            .foregroundStyle(.white)

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
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.11),
                    .purple.opacity(0.23)
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
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
        )
    }

    @ViewBuilder
    private var clubhousePhoto: some View {
        if let clubhouseImage = UIImage(
            named: clubhouseImageAssetName
        ) {
            Image(uiImage: clubhouseImage)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 245)
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )
        } else {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 22
                )
                .fill(.black.opacity(0.24))

                VStack(spacing: 12) {
                    Image(
                        systemName:
                        "building.2.crop.circle.fill"
                    )
                    .font(.system(size: 50))
                    .foregroundStyle(.cyan)

                    Text(
                        "Set clubhouseImageAssetName " +
                        "to the image used by HomeView."
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        .white.opacity(0.72)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 245)
        }
    }

    // MARK: - Request Inbox Card

    private var requestInboxCard: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.badge.fill")
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
            }

            if newRequestCount > 0 {
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
                        systemName:
                        "tray.full.fill"
                    )

                    Text("Open Request Inbox")

                    if newRequestCount > 0 {
                        Spacer()

                        Text("\(newRequestCount) New")
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
                        cornerRadius: 20
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
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(
                .cyan.opacity(0.54),
                lineWidth: 1.2
            )
        )
    }

    // MARK: - Refreshing

    @MainActor
    private func refreshVendorHome() async {
        async let profileTask: Void =
        loadVendorProfile()

        async let requestTask: Void =
        loadRequestCount()

        _ = await (
        profileTask,
        requestTask
        )
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
            forHTTPHeaderField: "Cache-Control"
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
        "\(vendorId)/service-requests?limit=1&offset=0"

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
            forHTTPHeaderField: "Cache-Control"
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

    // MARK: - Logo Preparation

    @MainActor
    private func prepareAndUploadLogo(
    from item: PhotosPickerItem
    ) async {
        guard vendorId > 0 else {
            logoMessage =
            "Vendor account not found."
            return
        }

        guard !isUploadingLogo else {
            return
        }

        isUploadingLogo = true
        logoMessage = ""

        defer {
            isUploadingLogo = false
            selectedLogoItem = nil
        }

        do {
            guard let originalData =
            try await item.loadTransferable(
                type: Data.self
            ),
            let originalImage =
            UIImage(
                data: originalData
            ) else {
                logoMessage =
                "Could not load the selected logo."
                return
            }

            let resizedLogo = resizedImage(
                originalImage,
                maxDimension: 1000
            )

            guard let jpegData =
            resizedLogo.jpegData(
                compressionQuality: 0.78
            ) else {
                logoMessage =
                "Could not prepare the selected logo."
                return
            }

            guard jpegData.count <=
            8_000_000 else {
                logoMessage =
                "The selected logo is too large."
                return
            }

            let encodedImage =
            jpegData.base64EncodedString()

            let imageDataURL =
            "data:image/jpeg;base64," +
            encodedImage

            await uploadLogo(
                imageDataURL
            )
        } catch is CancellationError {
            return
        } catch {
            logoMessage =
            "Could not load the selected logo."
        }
    }

    // MARK: - Logo Upload

    @MainActor
    private func uploadLogo(
    _ imageDataURL: String
    ) async {
        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/logo"

        guard let url = URL(
            string: urlString
        ) else {
            logoMessage =
            "Invalid logo upload URL."
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = "PATCH"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        do {
            request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "image_base64":
                    imageDataURL
                ],
                options: []
            )

            let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse =
            response as? HTTPURLResponse else {
                logoMessage =
                "Invalid response from server."
                return
            }

            let decoded =
            try JSONDecoder().decode(
                VendorLogoUploadResponse.self,
                from: data
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ),
            decoded.success == true else {
                logoMessage =
                decoded.error ??
                "Could not upload company logo."

                return
            }

            if let updatedVendor =
            decoded.vendor {
                vendor = updatedVendor

                saveVendorLocally(
                    updatedVendor
                )
            } else if let uploadedLogoURL =
            decoded.logo_url {
                storedLogoURL =
                uploadedLogoURL
            }

            logoMessage =
            decoded.message ??
            "Company logo updated successfully."
        } catch {
            logoMessage =
            error.localizedDescription
        }
    }

    // MARK: - Image Resizing

    private func resizedImage(
    _ image: UIImage,
    maxDimension: CGFloat
    ) -> UIImage {
        let originalSize = image.size

        let largestDimension = max(
            originalSize.width,
            originalSize.height
        )

        guard largestDimension >
        maxDimension else {
            return image
        }

        let scale =
        maxDimension /
        largestDimension

        let newSize = CGSize(
            width:
            originalSize.width *
            scale,
            height:
            originalSize.height *
            scale
        )

        let renderer =
        UIGraphicsImageRenderer(
            size: newSize
        )

        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: newSize
                )
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