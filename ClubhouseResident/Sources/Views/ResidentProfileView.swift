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

struct NeighborVendorProject: Identifiable {
    let id: String
    let vendorId: Int
    let vendorName: String
    let service: String
    let personId: Int
    let firstName: String?
    let address: String?
    let distanceMiles: Double?
    let finishedPhotoUrl: String?
}

struct ResidentProfileView: View {

    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentFirstName") private var firstName = ""
    @AppStorage("residentLastName") private var lastName = ""
    @AppStorage("residentPhone") private var phone = ""
    @AppStorage("residentAddress") private var address = ""
    @AppStorage("residentNeighborhoodName") private var neighborhoodName = ""
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentSignupProvider") private var residentSignupProvider = "email"
    @AppStorage("residentAppleUserId") private var residentAppleUserId = ""
    @AppStorage("residentDisplayAreaName") private var displayAreaName = ""

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

    @State private var selectedNeighborService = "All Services"
    @State private var selectedNeighborVendor = "All Vendors"
    @State private var neighborVendors: [Vendor] = []
    @State private var isLoadingNeighborVendors = false
    @State private var neighborVendorsLoaded = false
    @State private var showingAccountSettings = false

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

    private var neighborProjects: [NeighborVendorProject] {
        neighborVendors
        .flatMap { vendor in
            let people = vendor.signed_up_people ?? []

            return people.compactMap { person -> NeighborVendorProject? in
                guard let photoUrl = person.finished_photo_url,
                !photoUrl.isEmpty else {
                    return nil
                }

                if let status = person.photo_approval_status,
                !status.isEmpty,
                status != "approved" {
                    return nil
                }

                return NeighborVendorProject(
                    id: "\(vendor.id)-\(person.id)",
                    vendorId: vendor.id,
                    vendorName: vendor.company_name,
                    service: vendor.category ?? "Home Service",
                    personId: person.id,
                    firstName: person.first_name,
                    address: person.address,
                    distanceMiles: person.distance_miles,
                    finishedPhotoUrl: photoUrl
                )
            }
        }
        .sorted {
            ($0.distanceMiles ?? 9999) < ($1.distanceMiles ?? 9999)
        }
    }

    private var neighborServiceOptions: [String] {
        let services = neighborProjects.map { $0.service }.filter { !$0.isEmpty }
        return ["All Services"] + Array(Set(services)).sorted()
    }

    private var neighborVendorOptions: [String] {
        let vendors = neighborProjects.map { $0.vendorName }.filter { !$0.isEmpty }
        return ["All Vendors"] + Array(Set(vendors)).sorted()
    }

    private var filteredNeighborProjects: [NeighborVendorProject] {
        neighborProjects
        .filter { project in
            let serviceMatches = selectedNeighborService == "All Services" || project.service == selectedNeighborService
            let vendorMatches = selectedNeighborVendor == "All Vendors" || project.vendorName == selectedNeighborVendor
            return serviceMatches && vendorMatches
        }
        .prefix(10)
        .map { $0 }
    }

    private var accountSettingsBadge: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.35), .purple.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay(
                    Circle()
                    .stroke(.cyan.opacity(0.8), lineWidth: 1.5)
                )
                .shadow(color: .cyan.opacity(0.35), radius: 10)

                Image(systemName: "slider.horizontal.3")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            }

            Text("Account Settings")
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.88))
        }
    }

    private var serviceOptions: [String] {
        let vendorCategories = vendorOptions
        .compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let combined = vendorCategories + fallbackServiceOptions
        return Array(Set(combined)).sorted()
    }

    private var profileAreaName: String {
        let cleanNeighborhood = neighborhoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDisplayArea = displayAreaName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleanNeighborhood.isEmpty {
            return cleanNeighborhood
        }

        if !cleanDisplayArea.isEmpty {
            return cleanDisplayArea
        }

        return "Area not set"
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 24) {

                    Text("Resident Profile")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                    Text("Clubhouse Links is your portal to everyday home service contractors who have been used and trusted by your neighbors.")
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 12)
                    FlyingBirdHeroView()
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

                    /*
                    Button {
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
                    .padding(.top, 4)
                    */

                    /*
                    Button {
                        let keysToRemove = [
                            "residentId",
                            "residentFirstName",
                            "residentLastName",
                            "residentPhone",
                            "residentAddress",
                            "residentApprovalStatus",
                            "residentNeighborhoodId",
                            "residentNeighborhoodName",
                            "residentDisplayAreaName",
                            "residentIsSignedUp",
                            "residentSignupProvider",
                            "residentAppleUserId"
                        ]

                        for key in keysToRemove {
                            UserDefaults.standard.removeObject(forKey: key)
                        }

                        residentId = 0
                        firstName = ""
                        lastName = ""
                        phone = ""
                        address = ""
                        neighborhoodName = ""
                        displayAreaName = ""
                        residentIsSignedUp = false
                        residentSignupProvider = "email"
                        residentAppleUserId = ""
                    } label: {
                        Text("Reset Local App Storage")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    */

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
        }.sheet(isPresented: $showingAccountSettings) {
            AccountSettingsView()
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

            neighborProjectsCardBack
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
                .frame(height: 760)
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
            FlyingBirdSpriteHeroView()
            if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                missingAddressCard
            } else {
                AppleLookAroundCard(address: address)
                .frame(height: 110)
                .contentShape(Rectangle())
                .onTapGesture {
                    flipToNeighborProjects()
                }
            }

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

            Text("Swipe to see your completed projects")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.95))

            Text("Tap to see neighbor projects near you")
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
            .contentShape(Rectangle())
            .onTapGesture {
                flipToNeighborProjects()
            }

        }
        .frame(maxWidth: .infinity)
    }
    private func flipToNeighborProjects() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            isProfileFlipped = true
        }
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

            Text("Tap profile card to see neighbor projects")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }
    private var missingAddressCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.magnifyingglass")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(.cyan)

            Text("What’s your address?")
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text("Add your address to unlock Look Around, nearby vendors, and neighbor projects around you.")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .lineSpacing(3)

            Button {
                showingAccountSettings = true
            } label: {
                Text("Add Address")
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .cyan.opacity(0.35), radius: 10)
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(height: 210)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
            .stroke(.cyan.opacity(0.55), lineWidth: 1)
        )
    }
    private var residentInfoHeader: some View {
        VStack(spacing: 14) {
            Button {
                showingAccountSettings = true
            } label: {
                accountSettingsBadge
                .padding(.top, 8)
            }
            .buttonStyle(.plain)

            Text("\(firstName) \(lastName)")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)

            Text(profileAreaName)
            .font(.title2.bold())
            .foregroundStyle(.cyan)

            Text(phone)
            .font(.title3)
            .foregroundStyle(.white.opacity(0.82))

            Text(address)
            .font(.title3)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var neighborProjectsCardBack: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Neighbor Projects")
                .font(.title.bold())
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
                    .font(.headline)
                    .foregroundStyle(.cyan)
                }
            }

            Text("See trusted home service contractors used by neighbors near you.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.72))
            .lineSpacing(3)

            AppleLookAroundCard(address: address)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 10) {
                Text("Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker("Service", selection: $selectedNeighborService) {
                    ForEach(neighborServiceOptions, id: \.self) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Vendor")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker("Vendor", selection: $selectedNeighborVendor) {
                    ForEach(neighborVendorOptions, id: \.self) { vendor in
                        Text(vendor).tag(vendor)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if isLoadingNeighborVendors {
                ProgressView()
                .tint(.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else if filteredNeighborProjects.isEmpty {
                Text("No nearby completed projects found yet.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                TabView {
                    ForEach(filteredNeighborProjects) { project in
                        neighborProjectSlide(project)
                        .padding(.horizontal, 4)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.cyan.opacity(0.13), .purple.opacity(0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.55), lineWidth: 1)
        )
        .onAppear {
            loadNeighborVendorsIfNeeded()
        }
    }

    private func neighborProjectSlide(_ project: NeighborVendorProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let imageUrl = project.finishedPhotoUrl,
                !imageUrl.isEmpty,
                let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                        .resizable()
                        .scaledToFill()
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                            .fill(.black.opacity(0.25))
                            ProgressView()
                            .tint(.cyan)
                        }
                    }
                    .frame(width: 110, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                        .fill(.black.opacity(0.25))

                        Image(systemName: "house.and.flag.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                    }
                    .frame(width: 110, height: 90)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(project.vendorName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                    Text(project.service)
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)

                    if let firstName = project.firstName, !firstName.isEmpty {
                        Text("\(firstName) used this contractor")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                    }

                    if let distance = project.distanceMiles {
                        Text(String(format: "%.1f miles away", distance))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }

            if let address = project.address, !address.isEmpty {
                Text(address)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
            .stroke(.purple.opacity(0.45), lineWidth: 1)
        )
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

    private func loadNeighborVendorsIfNeeded() {
        guard !neighborVendorsLoaded else { return }
        guard residentId > 0 else { return }

        neighborVendorsLoaded = true
        isLoadingNeighborVendors = true

        let urlString = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/vendors/\(residentId)"

        guard let url = URL(string: urlString) else {
            isLoadingNeighborVendors = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingNeighborVendors = false
            }

            if let error = error {
                print("neighbor vendor error:", error.localizedDescription)
                return
            }

            guard let data = data else {
                print("No neighbor vendor data found.")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(VendorResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.success == true {
                        neighborVendors = decoded.vendors ?? []
                    } else {
                        print(decoded.error ?? "Could not load neighbor vendors.")
                    }
                }
            } catch {
                print("neighbor vendor decode error:", error)
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
            let placemarks = try await CLGeocoder().geocodeAddressString(address)

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