import SwiftUI
import PhotosUI
import MapKit
import UIKit

struct SubmitCompletedProjectResponse: Codable {
    let success: Bool?
    let project: ResidentCompletedProject?
    let message: String?
    let error: String?
}

struct RequestView: View {
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentSelectedTab") private var selectedTab = "home"

    @State private var selectedService = "Painting"
    @State private var selectedVendorId = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var uploadMessage = ""

    @State private var vendorOptions: [Vendor] = []
    @State private var vendorOptionsLoading = false
    @State private var vendorOptionsError = ""

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false

    @State private var manualVendorName = ""
    @State private var manualVendorPhone = ""



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

    private var serviceOptions: [String] {
        let vendorCategories = vendorOptions.compactMap { vendor -> String? in
            guard let category = vendor.category else {
                return nil
            }

            let cleanedCategory = category.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return cleanedCategory.isEmpty ? nil : cleanedCategory
        }

        return Array(Set(vendorCategories + fallbackServiceOptions)).sorted()
    }

    private var filteredVendorOptions: [Vendor] {
        let normalizedService = selectedService
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()

        return vendorOptions.filter { vendor in
            let normalizedCategory = (vendor.category ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

            return normalizedCategory == normalizedService
        }
    }

    private var isSignedIn: Bool {
        residentId > 0
    }

    private var cleanAddress: String {
        address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanPhone: String {
        phone.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanManualVendorName: String {
        manualVendorName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanManualVendorPhone: String {
        manualVendorPhone.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var manualVendorNameIsComplete: Bool {
        !cleanManualVendorName.isEmpty
    }

    private var residentDisplayName: String {
        let name = "\(firstName) \(lastName)"
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? "Your Home" : name
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Submit New Project")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                    Text("Share a finished project from a contractor you used so nearby neighbors can discover trusted home service providers.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(3)

                    residentCard

                    submitProjectCard

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onAppear {
            loadVendorOptions()
            loadResidentLookAround()
        }
        .onChange(of: residentId) { _ in
            loadResidentLookAround()

            if residentId > 0 {
                loadVendorOptions()
            } else {
                vendorOptions = []
                selectedVendorId = 0
                vendorOptionsLoading = false
                vendorOptionsError = "Resident profile not found."
            }
        }
        .onChange(of: address) { _ in
            loadResidentLookAround()
        }

        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else {
                selectedImage = nil
                return
            }

            loadSelectedPhoto(from: newItem)
        }
        .onChange(of: selectedVendorId) { _ in
            syncServiceToSelectedVendor()
        }
        .onChange(of: selectedService) { _ in
            manualVendorName = ""
            manualVendorPhone = ""
            uploadMessage = ""
            syncVendorSelectionForService()
        }
    }

    // MARK: - Resident / Look Around Card

    @ViewBuilder
    private var residentCard: some View {
        if isSignedIn,
        !cleanAddress.isEmpty,
        let lookAroundScene {
            lookAroundAddressCard(scene: lookAroundScene)
        } else {
            birdAddressFallbackCard
        }
    }

    @MainActor
    private func resetProjectFormAfterSubmission() {
        selectedPhotoItem = nil
        selectedImage = nil

        manualVendorName = ""
        manualVendorPhone = ""

        uploadMessage = ""
    }

    private func lookAroundAddressCard(
    scene: MKLookAroundScene
    ) -> some View {
        ZStack(alignment: .bottomLeading) {
            RequestLookAroundControllerView(scene: scene)
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .allowsHitTesting(false)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.08),
                    .black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                Label(
                    "Apple Look Around",
                    systemImage: "binoculars.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.cyan)

                Text(residentDisplayName)
                .font(.title2.bold())
                .foregroundStyle(.white)

                if !cleanPhone.isEmpty {
                    Text(cleanPhone)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                }

                Text(cleanAddress)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(.white.opacity(0.08))
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
            .stroke(
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .shadow(
            color: .cyan.opacity(0.25),
            radius: 12
        )
    }

    private var birdAddressFallbackCard: some View {
        VStack(spacing: 14) {
            FlyingBirdSpriteHeroView()
            .frame(height: 175)
            .padding(.top, 2)

            Text(fallbackCardTitle)
            .font(.title2.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)

            fallbackCardDescription

            if isLoadingLookAround {
                HStack(spacing: 8) {
                    ProgressView()
                    .tint(.cyan)

                    Text("Loading Apple Look Around...")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                }
                .padding(.top, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.10),
                    .purple.opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
            .stroke(
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .shadow(
            color: .cyan.opacity(0.25),
            radius: 12
        )
    }

    private var fallbackCardTitle: String {
        if !isSignedIn {
            return "Sign In to submit a project"
        }

        if cleanAddress.isEmpty {
            return "Add your address"
        }

        return residentDisplayName
    }

    @ViewBuilder
    private var fallbackCardDescription: some View {
        if !isSignedIn {
            Text("Sign in to see nearby completed projects.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        } else if cleanAddress.isEmpty {
            Text("Add your address from the Home screen to display your home and neighborhood.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        } else if isLoadingLookAround {
            Text(cleanAddress)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.cyan)
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        } else {
            VStack(spacing: 6) {
                Text(cleanAddress)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
                .multilineTextAlignment(.center)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text("Apple Look Around is not available at this address, so your address card is shown instead.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }

    // MARK: - Submit Project Card

    private var submitProjectCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Project Details")
            .font(.title2.bold())
            .foregroundStyle(.white)

            servicePickerSection

            vendorSection

            finishedProjectPhotoSection

            submitButton

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(uploadMessageColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
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

    private var servicePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Service")
            .font(.headline)
            .foregroundStyle(.cyan)

            Picker(
                "Service",
                selection: $selectedService
            ) {
                ForEach(serviceOptions, id: \.self) { service in
                    Text(service)
                    .tag(service)
                }
            }
            .pickerStyle(.menu)
            .tint(.cyan)
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(.black.opacity(0.22))
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
        }
    }

    @ViewBuilder
    private var vendorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                .foregroundStyle(.red.opacity(0.9))
            } else if filteredVendorOptions.isEmpty {
                manualVendorEntrySection
            } else {
                Picker(
                    "Vendor",
                    selection: $selectedVendorId
                ) {
                    ForEach(filteredVendorOptions) { vendor in
                        Text(vendor.company_name)
                        .tag(vendor.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(.cyan)
                .padding()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
            }
        }
    }

    private var manualVendorEntrySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter your \(selectedService.lowercased()) vendor's name and phone number below.")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.78))
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                .font(.caption.bold())
                .foregroundStyle(.cyan)

                TextField(
                    "\(selectedService) vendor's name",
                    text: $manualVendorName
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding()
                .foregroundStyle(.white)
                .background(.black.opacity(0.22))
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        .cyan.opacity(0.45),
                        lineWidth: 1
                    )
                )
            }

            if manualVendorNameIsComplete {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)

                    TextField(
                        "Vendor's phone number",
                        text: $manualVendorPhone
                    )
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.22))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            .orange.opacity(0.55),
                            lineWidth: 1
                        )
                    )
                    .transition(
                        .opacity.combined(
                            with: .move(edge: .top)
                        )
                    )
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.25),
            value: manualVendorNameIsComplete
        )
    }

    private var finishedProjectPhotoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Finished Project Photo")
            .font(.headline)
            .foregroundStyle(.cyan)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                VStack(spacing: 12) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .frame(maxWidth: .infinity)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18)
                        )
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                            .fill(.black.opacity(0.22))
                            .frame(height: 150)

                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                .font(.system(size: 34))
                                .foregroundStyle(.cyan)

                                Text("Upload Finished Photo")
                                .font(.headline.bold())
                                .foregroundStyle(.white)

                                Text("Tap to choose a completed project photo")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var submitButton: some View {
        Button {
            hideKeyboard()
            submitSelectedProject()
        } label: {
            Text("Submit Completed Work")
            .font(.headline)
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
                RoundedRectangle(cornerRadius: 18)
            )
            .shadow(
                color: .cyan.opacity(0.35),
                radius: 10
            )
        }
    }

    private var uploadMessageColor: Color {
        let normalizedMessage = uploadMessage.lowercased()

        if normalizedMessage.contains("please") ||
        normalizedMessage.contains("could not") ||
        normalizedMessage.contains("invalid") ||
        normalizedMessage.contains("not found") ||
        normalizedMessage.contains("error") {
            return .red
        }

        return .cyan
    }

    // MARK: - Apple Look Around

    private func loadResidentLookAround() {
        let requestedResidentId = residentId
        let requestedAddress = cleanAddress

        lookAroundScene = nil
        isLoadingLookAround = false

        guard requestedResidentId > 0,
        !requestedAddress.isEmpty else {
            return
        }

        isLoadingLookAround = true

        Task {
            do {
                let searchRequest = MKLocalSearch.Request()
                searchRequest.naturalLanguageQuery = requestedAddress
                searchRequest.resultTypes = .address

                let search = MKLocalSearch(request: searchRequest)
                let searchResponse = try await search.start()

                guard let mapItem = searchResponse.mapItems.first else {
                    await MainActor.run {
                        guard requestedResidentId == residentId,
                        requestedAddress == cleanAddress else {
                            return
                        }

                        lookAroundScene = nil
                        isLoadingLookAround = false
                    }

                    return
                }

                let sceneRequest = MKLookAroundSceneRequest(
                    mapItem: mapItem
                )

                let scene = try await sceneRequest.scene

                await MainActor.run {
                    guard requestedResidentId == residentId,
                    requestedAddress == cleanAddress else {
                        return
                    }

                    lookAroundScene = scene
                    isLoadingLookAround = false
                }
            } catch {
                await MainActor.run {
                    guard requestedResidentId == residentId,
                    requestedAddress == cleanAddress else {
                        return
                    }

                    lookAroundScene = nil
                    isLoadingLookAround = false
                }

                print(
                    "Apple Look Around error:",
                    error.localizedDescription
                )
            }
        }
    }

    // MARK: - Image Processing

    private func resizedImage(
    _ image: UIImage,
    maxDimension: CGFloat = 1400
    ) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)

        guard largestSide > maxDimension else {
            return image
        }

        let scale = maxDimension / largestSide

        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: newSize
                )
            )
        }
    }

    // MARK: - Vendor Loading

    private func loadVendorOptions() {
        guard residentId > 0 else {
            vendorOptions = []
            selectedVendorId = 0
            vendorOptionsLoading = false
            vendorOptionsError = "Create a new account to submit a project."
            return
        }

        vendorOptionsLoading = true
        vendorOptionsError = ""

        let urlString = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/vendors/\(residentId)"

        guard let url = URL(string: urlString) else {
            vendorOptionsLoading = false
            vendorOptionsError = "Invalid vendor URL."
            return
        }

        URLSession.shared.dataTask(with: url) {
            data,
            _,
            error in

            DispatchQueue.main.async {
                vendorOptionsLoading = false
            }

            if let error {
                DispatchQueue.main.async {
                    vendorOptionsError = error.localizedDescription
                }

                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    vendorOptionsError = "No vendors found."
                }

                return
            }

            do {
                let decoded = try JSONDecoder().decode(
                    VendorResponse.self,
                    from: data
                )

                DispatchQueue.main.async {
                    if decoded.success == true {
                        vendorOptions = decoded.vendors ?? []
                        vendorOptionsError = ""

                        if selectedVendorId == 0,
                        let firstVendor = vendorOptions.first {
                            selectedVendorId = firstVendor.id
                            selectedService = firstVendor.category ?? selectedService
                        } else {
                            syncVendorSelectionForService()
                        }
                    } else {
                        vendorOptions = []
                        selectedVendorId = 0
                        vendorOptionsError = decoded.error ?? "Could not load vendors."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    vendorOptions = []
                    selectedVendorId = 0
                    vendorOptionsError = String(
                        data: data,
                        encoding: .utf8
                    ) ?? "Could not decode vendors."
                }

                print(error)

                print(
                    String(
                        data: data,
                        encoding: .utf8
                    ) ?? ""
                )
            }
        }
        .resume()
    }

    private func syncVendorSelectionForService() {
        guard !filteredVendorOptions.isEmpty else {
            selectedVendorId = 0
            return
        }

        let currentSelectionIsValid = filteredVendorOptions.contains {
            $0.id == selectedVendorId
        }

        if !currentSelectionIsValid {
            selectedVendorId = filteredVendorOptions.first?.id ?? 0
        }
    }

    private func syncServiceToSelectedVendor() {
        guard let vendor = selectedVendor() else {
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

    // MARK: - Photo Selection

    private func loadSelectedPhoto(
    from item: PhotosPickerItem?
    ) {
        guard let item else {
            return
        }

        Task {
            do {
                if let data = try await item.loadTransferable(
                    type: Data.self
                ),
                let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        uploadMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    uploadMessage = "Could not load selected photo."
                }
            }
        }
    }

    // MARK: - Project Submission

    private func submitSelectedProject() {
        guard residentId > 0 else {
            uploadMessage = "Resident profile not found."
            return
        }

        guard !vendorOptionsLoading else {
            uploadMessage = "Please wait while vendors are loading."
            return
        }

        guard vendorOptionsError.isEmpty else {
            uploadMessage = vendorOptionsError
            return
        }

        let isEnteringManualVendor = filteredVendorOptions.isEmpty

        if isEnteringManualVendor {
            guard !cleanManualVendorName.isEmpty else {
                uploadMessage = "Please enter the vendor's name."
                return
            }

            guard !cleanManualVendorPhone.isEmpty else {
                uploadMessage = "Please enter the vendor's phone number."
                return
            }
        } else {
            guard selectedVendorId > 0 else {
                uploadMessage = "Please select a vendor."
                return
            }
        }

        guard let projectImage = selectedImage else {
            uploadMessage = "Please select a finished project photo first."
            return
        }

        let uploadImage = resizedImage(
            projectImage,
            maxDimension: 1400
        )

        guard let imageData = uploadImage.jpegData(
            compressionQuality: 0.65
        ) else {
            uploadMessage = "Could not prepare selected photo."
            return
        }

        let base64Image = imageData.base64EncodedString()
        let imageDataURL = "data:image/jpeg;base64,\(base64Image)"

        let selectedCategory = selectedVendor()?.category ?? selectedService

        var payload: [String: Any] = [
            "resident_id": residentId,
            "category": selectedCategory,
            "image_base64": imageDataURL
        ]

        if isEnteringManualVendor {
            payload["vendor_name"] = cleanManualVendorName
            payload["vendor_phone"] = cleanManualVendorPhone
        } else {
            payload["vendor_id"] = selectedVendorId
        }

        guard let url = URL(
            string: "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/completed-projects"
        ) else {
            uploadMessage = "Invalid completed project URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: payload,
                options: []
            )
        } catch {
            uploadMessage = "Could not prepare upload request."
            return
        }

        uploadMessage = "Submitting project..."

        URLSession.shared.dataTask(with: request) {
            data,
            _,
            error in

            if let error {
                DispatchQueue.main.async {
                    uploadMessage = error.localizedDescription
                }

                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    uploadMessage = "No response from server."
                }

                return
            }

            do {
                let decoded = try JSONDecoder().decode(
                    SubmitCompletedProjectResponse.self,
                    from: data
                )

                DispatchQueue.main.async {
                    if decoded.success == true {
                        let successMessage =
                        decoded.message ??
                        "Completed project submitted for review."

                        resetProjectFormAfterSubmission()

                        uploadMessage = successMessage

                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 0.9
                        ) {
                            uploadMessage = ""
                            selectedTab = "home"
                        }
                    } else {
                        uploadMessage =
                        decoded.error ??
                        "Could not submit completed project."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    uploadMessage = String(
                        data: data,
                        encoding: .utf8
                    ) ?? "Could not decode submit response."
                }

                print(
                    "Submit completed project decode error:",
                    error
                )

                print(
                    String(
                        data: data,
                        encoding: .utf8
                    ) ?? ""
                )
            }
        }
        .resume()
    }
}

// MARK: - Request Look Around UIKit Wrapper

private struct RequestLookAroundControllerView:
UIViewControllerRepresentable {

    let scene: MKLookAroundScene

    func makeUIViewController(
    context: Context
    ) -> MKLookAroundViewController {
        let controller = MKLookAroundViewController(
            scene: scene
        )

        controller.isNavigationEnabled = false
        controller.showsRoadLabels = false

        return controller
    }

    func updateUIViewController(
    _ controller: MKLookAroundViewController,
    context: Context
    ) {
        controller.scene = scene
        controller.isNavigationEnabled = false
        controller.showsRoadLabels = false
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif
