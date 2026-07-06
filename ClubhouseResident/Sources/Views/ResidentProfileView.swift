import SwiftUI
import PhotosUI
import MapKit

struct CompletedProjectsResponse: Codable {
    let success: Bool?
    let projects: [ResidentCompletedProject]?
    let error: String?
}

struct ResidentCompletedProject: Codable, Identifiable {
    let id: Int
    let resident_id: Int?
    let vendor_id: Int?
    let vendor_name: String?
    let service: String?
    let image_url: String?
    let approval_status: String?
    let moderation_status: String?
    let photo_rejection_reason: String?
}

struct ResidentProfileView: View {
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentNeighborhoodName") private var neighborhoodName = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false

    @State private var isProfileFlipped = false

    @State private var selectedService = "Painting"
    @State private var selectedVendorId = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var uploadMessage = ""

    @State private var vendorOptions: [Vendor] = []
    @State private var vendorOptionsLoading = false
    @State private var vendorOptionsError = ""

    @State private var completedProjects: [ResidentCompletedProject] = []
    @State private var completedProjectsLoading = false
    @State private var completedProjectsError = ""

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
        let vendorCategories = vendorOptions
        .compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let combined = vendorCategories + fallbackServiceOptions
        return Array(Set(combined)).sorted()
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {

                    Text("Resident Profile")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                    flippableProfileCard
                    NavigationLink {
                        VendorDirectoryView()
                    } label: {
                        Text("View Vendor Directory")
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
                        .shadow(color: .cyan.opacity(0.5), radius: 12)
                    }

                    NeonCard(
                        title: "Community Updates",
                        text: "View announcements, HOA updates, and neighborhood news for your community."
                    )

                    NeonCard(
                        title: "Events",
                        text: "See upcoming meetings, block parties, and neighborhood events."
                    )

                    NeonCard(
                        title: "Submit Vendor Request",
                        text: "Request a contractor, service provider, or local business recommendation."
                    )

/*                    Button {
                        residentIsSignedUp = false
                    } label: {
                        Text("Sign Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.top, 4)*/

                    Spacer(minLength: 90)
                }
                .padding()
            }
        }
        .onAppear {
            loadCompletedProjects()
            loadVendorOptions()
        }
        .onChange(of: selectedPhotoItem) { newItem in
            loadSelectedPhoto(from: newItem)
        }
        .onChange(of: selectedVendorId) { _ in
            syncServiceToSelectedVendor()
        }
    }

    private var flippableProfileCard: some View {
        ZStack {
            profileCardFront
            .opacity(isProfileFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isProfileFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    isProfileFlipped = true
                }
            }

            profileCardBack
            .opacity(isProfileFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isProfileFlipped ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: isProfileFlipped)
    }

    private var profileCardFront: some View {
        VStack(spacing: 10) {
            if completedProjectsLoading {
                profileInfoOnlySlide
                .overlay(
                    ProgressView()
                    .tint(.cyan)
                    .padding(.top, 150)
                )
            } else {
                TabView {
                    profileInfoOnlySlide

                    ForEach(completedProjects) { project in
                        profileProjectSlide(project)
                    }
                }
                .frame(height: 315)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: completedProjects.isEmpty ? .never : .automatic))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .cyan.opacity(0.25), radius: 10)
    }

    private var profileInfoOnlySlide: some View {
        VStack(spacing: 10) {

            AppleLookAroundCard(address: address)

            residentInfoHeader

            if !completedProjectsError.isEmpty {
                Text(completedProjectsError)
                .font(.caption)
                .foregroundStyle(.red.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            } else if completedProjects.isEmpty && !completedProjectsLoading {
                Text("No completed projects submitted yet.")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 4)
            }

            Text("Swipe to see completed projects")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.95))

            Text("Tap to submit a completed project")
            .font(.caption.bold())
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.yellow,
                        Color.orange,
                        Color.yellow.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func profileProjectSlide(_ project: ResidentCompletedProject) -> some View {
        VStack(spacing: 12) {
            residentInfoHeader

            HStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: project.image_url ?? "")) { image in
                    image
                    .resizable()
                    .scaledToFill()
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                        .fill(.black.opacity(0.25))

                        ProgressView()
                        .tint(.cyan)
                    }
                }
                .frame(width: 110, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 5) {
                    Text(project.vendor_name ?? "Vendor")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                    Text(project.service ?? "Service")
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)
                    .lineLimit(1)

                    approvalBadge(project.approval_status ?? "pending_review")

                    if let reason = project.photo_rejection_reason, !reason.isEmpty {
                        Text(reason)
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.9))
                        .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding()
            .background(.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text("Tap profile card to submit another project")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }

    private var residentInfoHeader: some View {
        VStack(spacing: 8) {
            Text("\(firstName) \(lastName)")
            .font(.title.bold())
            .foregroundStyle(.white)

            Text(neighborhoodName.isEmpty ? "Country Place" : neighborhoodName)
            .font(.headline)
            .foregroundStyle(.cyan)

            Text(phone)
            .foregroundStyle(.white.opacity(0.75))

            Text(address)
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
        }
    }

    private var profileCardBack: some View {
        VStack(alignment: .leading, spacing: 18) {

            HStack {
                Text("Submit New Project")
                .font(.title3.bold())
                .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        isProfileFlipped = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                        Text("Back")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)
                }
            }

            Text("Select the service, choose the vendor, and upload a finished project photo. Photos are reviewed before they appear publicly.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 8) {
                Text("Service")
                .font(.caption.bold())
                .foregroundStyle(.cyan)

                Picker("Service", selection: $selectedService) {
                    ForEach(serviceOptions, id: \.self) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .tint(.cyan)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vendor")
                .font(.caption.bold())
                .foregroundStyle(.cyan)

                if vendorOptionsLoading {
                    ProgressView()
                    .tint(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Picker("Vendor", selection: $selectedVendorId) {
                        Text("Select Vendor").tag(0)

                        ForEach(filteredVendorOptions) { vendor in
                            Text(vendor.company_name).tag(vendor.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .tint(.cyan)
                }

                if !vendorOptionsError.isEmpty {
                    Text(vendorOptionsError)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                }
            }

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                    .font(.title2)

                    Text(selectedImage == nil ? "Upload Finished Photo" : "Change Photo")
                    .font(.headline)

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
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

            if let selectedImage {
                Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button {
                submitSelectedProject()
            } label: {
                Text("Submit for Review")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background((selectedImage == nil || selectedVendorId == 0) ? .white.opacity(0.12) : .white.opacity(0.18))
                .foregroundStyle((selectedImage == nil || selectedVendorId == 0) ? .white.opacity(0.45) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(selectedImage == nil || selectedVendorId == 0)

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                .font(.caption)
                .foregroundStyle(.cyan)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }

            Button {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    isProfileFlipped = false
                }
            } label: {
                Text("Back to Profile")
                .font(.caption.bold())
                .foregroundStyle(.cyan.opacity(0.95))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.32),
                    .purple.opacity(0.30),
                    .cyan.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
            .stroke(
                LinearGradient(
                    colors: [.cyan, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .cyan.opacity(0.25), radius: 12)
    }

    private var filteredVendorOptions: [Vendor] {
        vendorOptions.filter { vendor in
            guard !selectedService.isEmpty else {
                return true
            }

            return (vendor.category ?? "") == selectedService
        }
    }

    private func approvalBadge(_ status: String) -> some View {
        let displayText: String
        let color: Color

        switch status {
        case "approved":
            displayText = "Approved"
            color = .green
        case "rejected":
            displayText = "Rejected"
            color = .red
        case "pending_review":
            displayText = "Review"
            color = .orange
        case "not_submitted":
            displayText = "No Photo"
            color = .gray
        default:
            displayText = "Pending"
            color = .yellow
        }

        return Text(displayText)
        .font(.caption.bold())
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private func loadCompletedProjects() {
        guard residentId > 0 else {
            completedProjectsError = "Resident profile not found."
            return
        }

        completedProjectsLoading = true
        completedProjectsError = ""

        let urlString = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/completed-projects/\(residentId)"

        guard let url = URL(string: urlString) else {
            completedProjectsLoading = false
            completedProjectsError = "Invalid completed projects URL."
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                completedProjectsLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    completedProjectsError = error.localizedDescription
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completedProjectsError = "No completed projects found."
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(CompletedProjectsResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.success == true {
                        completedProjects = decoded.projects ?? []
                    } else {
                        completedProjectsError = decoded.error ?? "Could not load completed projects."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completedProjectsError = String(data: data, encoding: .utf8) ?? "Could not decode completed projects."
                }
                print(error)
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()
    }

    private func loadVendorOptions() {
        guard residentId > 0 else {
            vendorOptionsError = "Resident profile not found."
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

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                vendorOptionsLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    vendorOptionsError = error.localizedDescription
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    vendorOptionsError = "No vendors found."
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(VendorResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.success == true {
                        vendorOptions = decoded.vendors ?? []

                        if selectedVendorId == 0, let firstVendor = vendorOptions.first {
                            selectedVendorId = firstVendor.id
                            selectedService = firstVendor.category ?? selectedService
                        }
                    } else {
                        vendorOptionsError = decoded.error ?? "Could not load vendors."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    vendorOptionsError = String(data: data, encoding: .utf8) ?? "Could not decode vendors."
                }
                print(error)
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()
    }

    private func syncServiceToSelectedVendor() {
        guard let vendor = selectedVendor() else {
            return
        }

        if let category = vendor.category, !category.isEmpty {
            selectedService = category
        }
    }

    private func selectedVendor() -> Vendor? {
        vendorOptions.first { $0.id == selectedVendorId }
    }

    private func loadSelectedPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
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

    private func submitSelectedProject() {
        guard selectedVendorId > 0 else {
            uploadMessage = "Please select a vendor."
            return
        }

        guard selectedImage != nil else {
            uploadMessage = "Please select a finished project photo first."
            return
        }

        let vendorName = selectedVendor()?.company_name ?? "selected vendor"

        uploadMessage = "Photo selected for \(vendorName). Backend upload is the next step."
    }
}

struct AppleLookAroundCard: View {
    let address: String

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoading = true
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let lookAroundScene {
                LookAroundControllerView(scene: lookAroundScene)
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.02),
                            .black.opacity(0.32)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                )
            } else {
                fallbackMapCard
            }

            if isLoading {
                ProgressView()
                .tint(.cyan)
            }
        }
        .task {
            await loadLookAroundScene()
        }
    }

    private var fallbackMapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
            .fill(.black.opacity(0.22))

            VStack(spacing: 6) {
                Image(systemName: didFail ? "map" : "binoculars.fill")
                .font(.system(size: 28))
                .foregroundStyle(.cyan)

                Text(didFail ? "Look Around unavailable here" : "Loading Apple Look Around")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
    }

    private func loadLookAroundScene() async {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                isLoading = false
                didFail = true
            }
            return
        }

        do {
            let placemarks = try await CLGeocoder().geocodeAddressString("\(address), Plano, TX")

            guard let coordinate = placemarks.first?.location?.coordinate else {
                await MainActor.run {
                    isLoading = false
                    didFail = true
                }
                return
            }

            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            let scene = try await request.scene

            await MainActor.run {
                self.lookAroundScene = scene
                self.isLoading = false
                self.didFail = scene == nil
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.didFail = true
            }
        }
    }
}

struct LookAroundControllerView: UIViewControllerRepresentable {
    let scene: MKLookAroundScene

    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let controller = MKLookAroundViewController(scene: scene)
        controller.isNavigationEnabled = false
        controller.showsRoadLabels = false
        return controller
    }

    func updateUIViewController(_ controller: MKLookAroundViewController, context: Context) {
        controller.scene = scene
    }
}