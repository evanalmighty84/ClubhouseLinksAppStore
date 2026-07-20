import SwiftUI
import PhotosUI

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
    @AppStorage("residentNeighborhoodName") private var neighborhoodName = ""
    @AppStorage("residentDisplayAreaName") private var displayAreaName = ""
    @AppStorage("residentSelectedTab") private var selectedTab = "home"

    @State private var selectedService = "Painting"
    @State private var selectedVendorId = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var uploadMessage = ""

    @State private var vendorOptions: [Vendor] = []
    @State private var vendorOptionsLoading = false
    @State private var vendorOptionsError = ""

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

    private var filteredVendorOptions: [Vendor] {
        vendorOptions.filter { vendor in
            guard !selectedService.isEmpty else {
                return true
            }

            return (vendor.category ?? "") == selectedService
        }
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

        return "Local Customer Area"
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
        }
        .onChange(of: selectedPhotoItem) { newItem in
            loadSelectedPhoto(from: newItem)
        }
        .onChange(of: selectedVendorId) { _ in
            syncServiceToSelectedVendor()
        }
    }

    private var residentCard: some View {
        VStack(spacing: 10) {
            Text("\(firstName) \(lastName)")
            .font(.title.bold())
            .foregroundStyle(.white)

            Text(profileAreaName)
            .font(.headline)
            .foregroundStyle(.cyan)

            Text(phone)
            .foregroundStyle(.white.opacity(0.75))

            Text(address)
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .cyan.opacity(0.25), radius: 10)
    }

    private var submitProjectCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Project Details")
            .font(.title2.bold())
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                Text("Service")
                .font(.headline)
                .foregroundStyle(.cyan)

                Picker("Service", selection: $selectedService) {
                    ForEach(serviceOptions, id: \.self) { service in
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

                if vendorOptionsLoading {
                    ProgressView()
                    .tint(.cyan)
                    .padding(.vertical, 12)
                } else if !vendorOptionsError.isEmpty {
                    Text(vendorOptionsError)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                } else if filteredVendorOptions.isEmpty {
                    Text("No vendors found for this service.")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.65))
                } else {
                    Picker("Vendor", selection: $selectedVendorId) {
                        ForEach(filteredVendorOptions) { vendor in
                            Text(vendor.company_name).tag(vendor.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

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
                            .clipShape(RoundedRectangle(cornerRadius: 18))
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

            Button {
                hideKeyboard()
                submitSelectedProject()
            } label: {
                Text("Submit for Review")
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
                .shadow(color: .cyan.opacity(0.35), radius: 10)
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(uploadMessage.lowercased().contains("please") ? .red : .cyan)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
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
        guard residentId > 0 else {
            uploadMessage = "Resident profile not found."
            return
        }

        guard selectedVendorId > 0 else {
            uploadMessage = "Please select a vendor."
            return
        }

        guard let selectedImage else {
            uploadMessage = "Please select a finished project photo first."
            return
        }

        guard let imageData = selectedImage.jpegData(compressionQuality: 0.82) else {
            uploadMessage = "Could not prepare selected photo."
            return
        }

        let base64Image = imageData.base64EncodedString()
        let imageDataUrl = "data:image/jpeg;base64,\(base64Image)"

        let selectedCategory =
        selectedVendor()?.category ??
        selectedService

        let payload: [String: Any] = [
            "resident_id": residentId,
            "vendor_id": selectedVendorId,
            "category": selectedCategory,
            "image_base64": imageDataUrl
        ]

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

        URLSession.shared.dataTask(with: request) { data, _, error in
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
                        uploadMessage =
                        decoded.message ??
                        "Completed project submitted for review."

                        selectedPhotoItem = nil
                        selectedImage = nil

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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
                    uploadMessage =
                    String(data: data, encoding: .utf8) ??
                    "Could not decode submit response."
                }

                print("submit completed project decode error:", error)
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()
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