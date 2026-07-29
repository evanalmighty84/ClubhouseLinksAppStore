import SwiftUI
import MapKit
import UIKit

struct VendorCompletedProjectsResponse: Codable {
    let success: Bool
    let projects: [VendorCompletedProject]?
    let total_count: Int?
    let error: String?
}

struct VendorCompletedProject: Codable, Identifiable {
    let id: Int
    let resident_id: Int?
    let vendor_id: Int?

    let vendor_name: String?
    let vendor_category: String?

    let service: String?
    let image_url: String?
    let approval_status: String?
    let moderation_status: String?

    let photo_submitted_at: String?
    let photo_approved_at: String?
    let photo_rejected_at: String?
    let photo_rejection_reason: String?

    let resident_first_name: String?
    let resident_last_name: String?
    let resident_phone: String?
    let resident_address: String?
    let resident_display_area_name: String?
}

private struct VendorProjectHouse: Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let phone: String
    let address: String
    let displayAreaName: String
    let projects: [VendorCompletedProject]

    var residentName: String {
        let fullName = "\(firstName) \(lastName)"
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return fullName.isEmpty
        ? "Customer"
        : fullName
    }
}

struct VendorCompletedProjectsView: View {
    let vendorId: Int

    @AppStorage("vendorCompanyName")
    private var vendorCompanyName = ""

    @State private var projects: [VendorCompletedProject] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    private var houses: [VendorProjectHouse] {
        var projectGroups:
        [Int: [VendorCompletedProject]] = [:]

        var orderedResidentIds: [Int] = []

        for project in projects {
            /*
             * Every normal project should have resident_id.
             * The negative project ID is only a safe fallback.
             */
            let groupId =
            project.resident_id ??
                -project.id

            if projectGroups[groupId] == nil {
                projectGroups[groupId] = []
                orderedResidentIds.append(groupId)
            }

            projectGroups[groupId, default: []]
            .append(project)
        }

        return orderedResidentIds.compactMap { groupId in
            guard let groupedProjects =
            projectGroups[groupId],
            let firstProject =
            groupedProjects.first else {
                return nil
            }

            return VendorProjectHouse(
                id: groupId,
                firstName:
                clean(
                    firstProject.resident_first_name
                ) ?? "",
                lastName:
                clean(
                    firstProject.resident_last_name
                ) ?? "",
                phone:
                clean(
                    firstProject.resident_phone
                ) ?? "",
                address:
                clean(
                    firstProject.resident_address
                ) ?? "",
                displayAreaName:
                clean(
                    firstProject
                    .resident_display_area_name
                ) ?? "",
                projects:
                groupedProjects
            )
        }
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {
                    header

                    content

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .refreshable {
                await loadProjects()
            }
        }
        .task(id: vendorId) {
            await loadProjects()
        }
    }

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("Completed Projects")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            if !vendorCompanyName.isEmpty {
                Text(vendorCompanyName.uppercased())
                .font(.headline.bold())
                .foregroundStyle(.cyan)
            }

            Text(
                "Homes and completed projects shared by " +
                "customers who used your company."
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.76))
            .lineSpacing(3)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && projects.isEmpty {
            loadingView

        } else if !errorMessage.isEmpty &&
        projects.isEmpty {
            errorView

        } else if houses.isEmpty {
            emptyView

        } else {
            LazyVStack(spacing: 30) {
                ForEach(houses) { house in
                    VendorHouseProjectsSection(
                        house: house
                    )
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            .tint(.cyan)

            Text("Loading customer projects...")
            .foregroundStyle(
                .white.opacity(0.72)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(
                systemName:
                "exclamationmark.triangle.fill"
            )
            .font(.system(size: 40))
            .foregroundStyle(.orange)

            Text(errorMessage)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadProjects()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(
            RoundedRectangle(cornerRadius: 26)
        )
    }

    private var emptyView: some View {
        VStack(spacing: 15) {
            Image(
                systemName:
                "house.and.flag.fill"
            )
            .font(.system(size: 44))
            .foregroundStyle(.cyan)

            Text("No customer projects yet")
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text(
                "A home and its finished-project photos " +
                "will appear here after a customer uploads " +
                "completed work for your company."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.68))
            .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.12),
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
                .cyan.opacity(0.5),
                lineWidth: 1
            )
        )
    }

    @MainActor
    private func loadProjects() async {
        guard vendorId > 0 else {
            errorMessage =
            "Vendor account not found."
            return
        }

        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = ""

        defer {
            isLoading = false
        }

        let urlString =
        "https://crm-function-app-5d4de511071d.herokuapp.com" +
        "/server/resident_function/api/vendors/" +
        "\(vendorId)/completed-projects"

        guard let url =
        URL(string: urlString) else {
            errorMessage =
            "Invalid completed-project URL."
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
                throw URLError(
                    .badServerResponse
                )
            }

            let decoded =
            try JSONDecoder().decode(
                VendorCompletedProjectsResponse.self,
                from: data
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ),
            decoded.success else {
                errorMessage =
                decoded.error ??
                "Could not load completed projects."

                return
            }

            projects =
            decoded.projects ?? []

        } catch is CancellationError {
            return

        } catch let error as URLError
        where error.code == .cancelled {
            return

        } catch {
            errorMessage =
            error.localizedDescription
        }
    }

    private func clean(
    _ value: String?
    ) -> String? {
        let cleaned =
        value?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        return cleaned.isEmpty
        ? nil
        : cleaned
    }
}

private struct VendorHouseProjectsSection: View {
    let house: VendorProjectHouse

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            VendorHouseLookAroundCard(
                house: house
            )

            HStack {
                Text(
                    house.projects.count == 1
                    ? "1 Completed Project"
                    : "\(house.projects.count) Completed Projects"
                )
                .font(.headline.bold())
                .foregroundStyle(.white)

                Spacer()

                if house.projects.count > 1 {
                    Label(
                        "Swipe",
                        systemImage:
                        "hand.draw.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)
                }
            }
            .padding(.horizontal, 4)

            TabView {
                ForEach(house.projects) {
                    project in

                    VendorCompletedProjectCard(
                        project: project
                    )
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: 430)
            .tabViewStyle(
                .page(
                    indexDisplayMode:
                    house.projects.count > 1
                    ? .automatic
                    : .never
                )
            )
        }
    }
}

private struct VendorHouseLookAroundCard: View {
    let house: VendorProjectHouse

    @State private var lookAroundScene:
    MKLookAroundScene?

    @State private var isLoading = false
    @State private var didFail = false

    private var phoneDigits: String {
        house.phone.filter(\.isNumber)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            lookAroundContent

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.08),
                    .black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            customerInformation
        }
        .frame(maxWidth: .infinity)
        .frame(height: 290)
        .background(.black.opacity(0.24))
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
                lineWidth: 1.5
            )
        )
        .shadow(
            color: .cyan.opacity(0.22),
            radius: 14
        )
        .task(id: house.address) {
            await loadLookAround()
        }
    }

    @ViewBuilder
    private var lookAroundContent: some View {
        if let lookAroundScene {
            VendorLookAroundControllerView(
                scene: lookAroundScene
            )
            .frame(maxWidth: .infinity)
            .frame(height: 290)
            .allowsHitTesting(false)

        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        .cyan.opacity(0.18),
                        .purple.opacity(0.34),
                        .black.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                        .tint(.cyan)

                        Text(
                            "Loading Apple Look Around..."
                        )
                        .font(.caption.bold())
                        .foregroundStyle(
                            .white.opacity(0.74)
                        )

                    } else {
                        Image(
                            systemName:
                            didFail
                            ? "house.fill"
                            : "binoculars.fill"
                        )
                        .font(.system(size: 46))
                        .foregroundStyle(.cyan)

                        Text(
                            didFail
                            ? "Apple Look Around is not available for this house."
                            : "Preparing Apple Look Around..."
                        )
                        .font(.caption.bold())
                        .foregroundStyle(
                            .white.opacity(0.74)
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }
                }
            }
            .frame(height: 290)
        }
    }

    private var customerInformation: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Label(
                "Customer Home",
                systemImage: "house.fill"
            )
            .font(.caption.bold())
            .foregroundStyle(.cyan)

            Text(house.residentName)
            .font(.title2.bold())
            .foregroundStyle(.white)

            if !house.phone.isEmpty,
            !phoneDigits.isEmpty,
            let phoneURL =
            URL(
                string:
                "tel://\(phoneDigits)"
            ) {
                Link(
                    destination: phoneURL
                ) {
                    Label(
                        house.phone,
                        systemImage:
                        "phone.fill"
                    )
                    .font(.subheadline.weight(
                        .semibold
                    ))
                }
                .foregroundStyle(
                    .white.opacity(0.88)
                )
            }

            if !house.address.isEmpty {
                Label(
                    house.address,
                    systemImage:
                    "mappin.and.ellipse"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.90)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            } else if !house.displayAreaName.isEmpty {
                Label(
                    house.displayAreaName,
                    systemImage:
                    "mappin.and.ellipse"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.90)
                )
            }
        }
        .padding(18)
    }

    @MainActor
    private func loadLookAround() async {
        let requestedAddress =
        house.address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        lookAroundScene = nil
        didFail = false

        guard !requestedAddress.isEmpty else {
            didFail = true
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let searchRequest =
            MKLocalSearch.Request()

            searchRequest.naturalLanguageQuery =
            requestedAddress

            searchRequest.resultTypes =
            .address

            let search =
            MKLocalSearch(
                request: searchRequest
            )

            let response =
            try await search.start()

            guard let mapItem =
            response.mapItems.first else {
                didFail = true
                return
            }

            let sceneRequest =
            MKLookAroundSceneRequest(
                mapItem: mapItem
            )

            let scene =
            try await sceneRequest.scene

            lookAroundScene = scene
            didFail = scene == nil

        } catch is CancellationError {
            return

        } catch {
            didFail = true

            print(
                "Vendor Apple Look Around error:",
                error.localizedDescription
            )
        }
    }
}

private struct VendorCompletedProjectCard: View {
    let project: VendorCompletedProject

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            projectImage

            Text(
                clean(project.service) ??
                "Completed Project"
            )
            .font(.title2.bold())
            .foregroundStyle(.white)

            HStack {
                Label(
                    projectStatus,
                    systemImage:
                    "checkmark.seal.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.cyan)

                Spacer()

                if let submittedDate =
                formattedDate(
                    project
                    .photo_submitted_at
                ) {
                    Text(submittedDate)
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.66)
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.12),
                    .purple.opacity(0.28)
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
                .cyan.opacity(0.48),
                lineWidth: 1
            )
        )
    }

    @ViewBuilder
    private var projectImage: some View {
        if let imageString =
        clean(project.image_url),
        let imageURL =
        URL(string: imageString) {
            AsyncImage(url: imageURL) {
                phase in

                switch phase {
                case .empty:
                    ProgressView()
                    .tint(.cyan)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 290
                    )

                case .success(let image):
                    image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 290)
                    .frame(
                        maxWidth: .infinity
                    )
                    .clipped()

                case .failure:
                    imagePlaceholder

                @unknown default:
                    imagePlaceholder
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 22
            )
            .fill(.black.opacity(0.24))
            .frame(height: 290)

            Image(systemName: "photo")
            .font(.system(size: 42))
            .foregroundStyle(.cyan)
        }
    }

    private var projectStatus: String {
        clean(project.approval_status)?
        .capitalized ??
        clean(project.moderation_status)?
        .capitalized ??
        "Submitted"
    }

    private func clean(
    _ value: String?
    ) -> String? {
        let cleaned =
        value?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        return cleaned.isEmpty
        ? nil
        : cleaned
    }

    private func formattedDate(
    _ value: String?
    ) -> String? {
        guard let value =
        clean(value) else {
            return nil
        }

        let fractionalFormatter =
        ISO8601DateFormatter()

        fractionalFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let standardFormatter =
        ISO8601DateFormatter()

        guard let date =
        fractionalFormatter.date(
            from: value
        ) ??
        standardFormatter.date(
            from: value
        ) else {
            return nil
        }

        return date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}

private struct VendorLookAroundControllerView:
UIViewControllerRepresentable {

    let scene: MKLookAroundScene

    func makeUIViewController(
    context: Context
    ) -> MKLookAroundViewController {
        let controller =
        MKLookAroundViewController(
            scene: scene
        )

        controller.isNavigationEnabled =
        false

        controller.showsRoadLabels =
        false

        return controller
    }

    func updateUIViewController(
    _ controller:
    MKLookAroundViewController,
    context: Context
    ) {
        controller.scene = scene

        controller.isNavigationEnabled =
        false

        controller.showsRoadLabels =
        false
    }
}