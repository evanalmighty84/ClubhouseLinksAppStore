import SwiftUI
import PhotosUI
import UIKit

struct VendorHomeView: View {
    @AppStorage("vendorId")
    private var vendorId = 0

    @AppStorage("vendorCompanyName")
    private var storedCompanyName = ""

    @AppStorage("vendorCategory")
    private var storedCategory = ""

    @AppStorage("vendorLogoURL")
    private var storedLogoURL = ""

    @State private var vendor: VendorAccount?

    @State private var selectedLogoItem:
    PhotosPickerItem?

    @State private var isLoadingProfile = false
    @State private var isUploadingLogo = false
    @State private var logoMessage = ""

    private var companyName: String {
        let value =
        vendor?.company_name
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !value.isEmpty {
            return value
        }

        let stored =
        storedCompanyName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return stored.isEmpty
        ? "Vendor Account"
        : stored
    }

    private var categoryName: String {
        let value =
        vendor?.category?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !value.isEmpty {
            return value
        }

        return storedCategory.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var logoURLString: String? {
        let profileLogo =
        vendor?.logo_url?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if !profileLogo.isEmpty {
            return profileLogo
        }

        let stored =
        storedLogoURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return stored.isEmpty
        ? nil
        : stored
    }

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

                        clubhouseHeroCard

                        requestInboxCard

                        Spacer(minLength: 120)
                    }
                    .padding()
                }
                .refreshable {
                    await loadVendorProfile()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task(id: vendorId) {
            await loadVendorProfile()
        }
        .onChange(
            of: selectedLogoItem
        ) { newItem in
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
        VStack(spacing: 12) {
            HStack {
                Spacer()

                NavigationLink {
                    AccountSettingsView()
                } label: {
                    accountSettingsBadge
                }
                .buttonStyle(.plain)
            }

            Text(companyName.uppercased())
            .font(.largeTitle.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.65)
            .lineLimit(2)

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
                .padding(.top, 4)
            }
        }
    }

    private var accountSettingsBadge: some View {
        HStack(spacing: 8) {
            Image(
                systemName:
                "slider.horizontal.3"
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
        .overlay(
            Capsule()
            .stroke(
                .cyan.opacity(0.40),
                lineWidth: 1
            )
        )
    }

    // MARK: - Vendor Logo

    private var vendorLogoCard: some View {
        VStack(spacing: 16) {
            if let logoURLString,
            let logoURL =
            URL(string: logoURLString) {
                existingLogoView(
                    logoURL: logoURL
                )
            } else {
                uploadLogoPlaceholder
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
                .font(.subheadline.weight(
                    .semibold
                ))
                .foregroundStyle(
                    logoMessageColor
                )
                .multilineTextAlignment(
                    .center
                )
                .frame(
                    maxWidth: .infinity
                )
            }
        }
        .padding(20)
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
            RoundedRectangle(
                cornerRadius: 28
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 28
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
                lineWidth: 1.2
            )
        )
        .shadow(
            color: .cyan.opacity(0.18),
            radius: 12
        )
    }

    private func existingLogoView(
    logoURL: URL
    ) -> some View {
        VStack(spacing: 15) {
            AsyncImage(
                url: logoURL,
                transaction:
                Transaction(
                    animation:
                    .easeInOut(
                        duration: 0.25
                    )
                )
            ) { phase in
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
                        .white.opacity(0.94)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 22
                        )
                    )

                case .failure:
                    uploadLogoPlaceholder

                @unknown default:
                    uploadLogoPlaceholder
                }
            }

            PhotosPicker(
                selection: $selectedLogoItem,
                matching: .images
            ) {
                Label(
                    "Change Company Logo",
                    systemImage:
                    "photo.badge.plus"
                )
                .font(.subheadline.bold())
                .foregroundStyle(.cyan)
                .padding(.horizontal, 16)
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

    private var uploadLogoPlaceholder: some View {
        PhotosPicker(
            selection: $selectedLogoItem,
            matching: .images
        ) {
            VStack(spacing: 15) {
                Image(
                    systemName:
                    "photo.badge.plus"
                )
                .font(
                    .system(size: 52)
                )
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
                    .white.opacity(0.70)
                )
                .multilineTextAlignment(
                    .center
                )

                Text("Choose Logo")
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
            .padding(22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 230)
        }
        .buttonStyle(.plain)
        .disabled(isUploadingLogo)
    }

    // MARK: - Clubhouse Hero

    private var clubhouseHeroCard: some View {
        VStack(spacing: 15) {
            FlyingBirdHeroView()
            .frame(height: 220)

            Text("Clubhouse Links")
            .font(.title2.bold())
            .foregroundStyle(.white)

            Text(
                "Your connection to homeowners, " +
                "completed projects, events, and new " +
                "service opportunities."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.10),
                    .purple.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 28
            )
            .stroke(
                .purple.opacity(0.58),
                lineWidth: 1
            )
        )
    }

    // MARK: - Request Inbox

    private var requestInboxCard: some View {
        VStack(spacing: 20) {
            Image(
                systemName:
                "bell.badge.fill"
            )
            .font(
                .system(size: 60)
            )
            .foregroundStyle(.cyan)

            Text("Resident Service Requests")
            .font(.title2.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(
                .center
            )

            Text(
                "New requests from residents will be " +
                "delivered to your request inbox."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.70)
            )
            .multilineTextAlignment(
                .center
            )
            .lineSpacing(3)

            NavigationLink {
                VendorRequestsView()
            } label: {
                Label(
                    "Open Request Inbox",
                    systemImage:
                    "tray.full.fill"
                )
                .font(.headline.bold())
                .frame(
                    maxWidth: .infinity
                )
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
                    .cyan.opacity(0.12),
                    .purple.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 28
            )
            .stroke(
                .cyan.opacity(0.52),
                lineWidth: 1
            )
        )
    }

    // MARK: - Profile Loading

    @MainActor
    private func loadVendorProfile() async {
        guard vendorId > 0 else {
            return
        }

        guard !isLoadingProfile else {
            return
        }

        isLoadingProfile = true

        defer {
            isLoadingProfile = false
        }

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/profile"

        guard let url =
        URL(string: urlString) else {
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
                VendorProfileResponse.self,
                from: data
            )

            guard decoded.success == true,
            let loadedVendor =
            decoded.vendor else {
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
            print(
                "Vendor profile error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Logo Upload

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

            let resizedLogo =
            resizedImage(
                originalImage,
                maxDimension: 1200
            )

            guard let jpegData =
            resizedLogo.jpegData(
                compressionQuality: 0.78
            ) else {
                logoMessage =
                "Could not prepare the logo image."
                return
            }

            /*
             * Keep the JSON body comfortably below
             * typical Express request limits.
             */
            guard jpegData.count <= 8_000_000 else {
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
        } catch {
            logoMessage =
            "Could not load the selected logo."
        }
    }

    @MainActor
    private func uploadLogo(
    _ imageDataURL: String
    ) async {
        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/logo"

        guard let url =
        URL(string: urlString) else {
            logoMessage =
            "Invalid logo-upload URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Content-Type"
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
            } else if let newLogoURL =
            decoded.logo_url {
                storedLogoURL =
                newLogoURL
            }

            logoMessage =
            decoded.message ??
            "Company logo updated successfully."
        } catch {
            logoMessage =
            error.localizedDescription
        }
    }

    private func resizedImage(
    _ image: UIImage,
    maxDimension: CGFloat
    ) -> UIImage {
        let originalSize = image.size

        let largestDimension =
        max(
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

    private var logoMessageColor: Color {
        let normalized =
        logoMessage.lowercased()

        if normalized.contains("could not") ||
        normalized.contains("invalid") ||
        normalized.contains("too large") ||
        normalized.contains("not found") ||
        normalized.contains("error") {
            return .red
        }

        return .cyan
    }
}