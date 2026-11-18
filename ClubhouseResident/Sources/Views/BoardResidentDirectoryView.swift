import SwiftUI
import UniformTypeIdentifiers

// The server remains the source of truth for board permissions and community IDs.
// This screen reuses the credential returned by the normal resident verification.
private enum BoardRosterAPI {
    static let base = "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api"

    static func call(_ method: String, boardId: Int, suffix: String = "",
                     token: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard !token.isEmpty,
              let url = URL(string: "\(base)/hoaBoardMembers/\(boardId)/resident-roster\(suffix)") else {
            throw RosterFailure("Sign in normally as your HOA board account to access the directory.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 55
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard let status = (response as? HTTPURLResponse)?.statusCode,
              (200..<300).contains(status) else {
            throw RosterFailure(json["error"] as? String ?? "The resident directory request failed.")
        }
        return json
    }
}

private struct RosterFailure: LocalizedError {
    let description: String
    init(_ description: String) { self.description = description }
    var errorDescription: String? { description }
}

private struct BoardResident: Identifiable {
    let id: Int
    var firstName: String
    var lastName: String
    var approval: String
    var isBoard: Bool

    init?(_ object: [String: Any]) {
        guard let id = object["id"] as? Int else { return nil }
        self.id = id
        firstName = object["first_name"] as? String ?? ""
        lastName = object["last_name"] as? String ?? ""
        approval = object["approval_status"] as? String ?? ""
        isBoard = object["board_of_directors"] as? Bool ?? false
    }
}

private struct DirectoryCandidate: Identifiable {
    let id = UUID()
    var firstName: String
    var lastName: String
    var phone: String
    var address: String
    var selected = true

    init(_ json: [String: Any]) {
        firstName = json["first_name"] as? String ?? ""
        lastName = json["last_name"] as? String ?? ""
        phone = json["phone"] as? String ?? ""
        address = json["address"] as? String ?? ""
    }
    var payload: [String: Any] {
        ["first_name": firstName.trimmingCharacters(in: .whitespacesAndNewlines),
         "last_name": lastName.trimmingCharacters(in: .whitespacesAndNewlines),
         "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
         "address": address.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
}

struct BoardResidentDirectoryView: View {
    let boardId: Int
    let token: String

    @Environment(\.dismiss) private var dismiss
    @State private var residents: [BoardResident] = []
    @State private var community = ""
    @State private var inviteCode = ""
    @State private var search = ""
    @State private var error = ""
    @State private var message = ""
    @State private var busy = false
    @State private var showingAdd = false
    @State private var showingImport = false
    @State private var selectedResident: BoardResident?

    private var filtered: [BoardResident] {
        guard !search.isEmpty else { return residents }
        return residents.filter {
            "\($0.firstName) \($0.lastName) \($0.id)".localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("HOA Residents").font(.largeTitle.bold()).foregroundStyle(.white)
                    if token.isEmpty {
                        Text("Board authorization is not available in the current login. Sign in as the board member through the normal Clubhouse Links signup/login flow.")
                            .foregroundStyle(.orange)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(community.isEmpty ? "Your HOA resident directory" : community)
                                .font(.title2.bold())
                            Text("Resident Invite Code").font(.caption).foregroundStyle(.cyan)
                            Text(inviteCode.isEmpty ? "No active resident invite code" : inviteCode)
                                .font(.headline).textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        Button("Add Resident") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(busy || inviteCode.isEmpty)
                        Button("Upload Resident Directory") { showingImport = true }
                            .buttonStyle(.bordered)
                            .disabled(busy || inviteCode.isEmpty)

                        TextField("Search residents by name or ID", text: $search)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Text("\(residents.count) community residents")
                                .foregroundStyle(.cyan)
                            Spacer()
                            Button("Refresh") { Task { await refresh() } }.disabled(busy)
                        }
                        ForEach(filtered) { resident in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(resident.firstName) \(resident.lastName)")
                                        .font(.headline)
                                    Text("ID \(resident.id) · \(resident.approval)")
                                        .font(.caption).foregroundStyle(.cyan)
                                    if resident.isBoard {
                                        Text("Board member (protected)").font(.caption)
                                    }
                                }
                                Spacer()
                                if !resident.isBoard {
                                    Button("Edit") { selectedResident = resident }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    if busy { ProgressView().tint(.cyan) }
                    if !error.isEmpty { Text(error).foregroundStyle(.orange) }
                    if !message.isEmpty { Text(message).foregroundStyle(.green) }
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .navigationTitle("Resident Directory")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: boardId) { await refresh() }
        .sheet(isPresented: $showingAdd) {
            BoardAddResidentView(boardId: boardId, token: token) {
                showingAdd = false
                Task { await refresh() }
            }
        }
        .sheet(isPresented: $showingImport) {
            BoardDirectoryImportView(boardId: boardId, token: token, community: community) {
                showingImport = false
                Task { await refresh() }
            }
        }
        .sheet(item: $selectedResident) { resident in
            BoardEditResidentView(boardId: boardId, token: token, resident: resident) {
                selectedResident = nil
                Task { await refresh() }
            }
        }
    }

    @MainActor private func refresh() async {
        guard !token.isEmpty, !busy else { return }
        busy = true
        error = ""
        defer { busy = false }
        do {
            let response = try await BoardRosterAPI.call("GET", boardId: boardId, token: token)
            let area = response["community"] as? [String: Any] ?? [:]
            community = area["neighborhood_name"] as? String ?? ""
            inviteCode = area["invite_code"] as? String ?? ""
            residents = (response["residents"] as? [[String: Any]] ?? []).compactMap(BoardResident.init)
        } catch { self.error = error.localizedDescription }
    }
}

private struct BoardAddResidentView: View {
    let boardId: Int
    let token: String
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var first = ""
    @State private var last = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var busy = false
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("First Name", text: $first)
                TextField("Last Name", text: $last)
                TextField("Mobile Phone", text: $phone).keyboardType(.phonePad)
                TextField("Home Address", text: $address)
                Text("New residents will be approved for the board member's community. They must verify their own mobile number when signing in.")
                    .font(.caption)
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                Button(busy ? "Saving…" : "Add Resident") {
                    Task { await save() }
                }
                .disabled(busy || first.isEmpty || last.isEmpty || phone.isEmpty || address.isEmpty)
            }
            .navigationTitle("Add Resident")
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            } }
        }
    }

    @MainActor private func save() async {
        busy = true
        defer { busy = false }
        do {
            _ = try await BoardRosterAPI.call("POST", boardId: boardId, token: token,
                body: ["first_name": first, "last_name": last,
                       "phone": phone, "address": address])
            onSaved()
        } catch { self.error = error.localizedDescription }
    }
}

private struct BoardEditResidentView: View {
    let boardId: Int
    let token: String
    let resident: BoardResident
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var first = ""
    @State private var last = ""
    @State private var status = "pending"
    @State private var busy = false
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("First Name", text: $first)
                TextField("Last Name", text: $last)
                Picker("Approval Status", selection: $status) {
                    Text("Pending").tag("pending")
                    Text("Approved").tag("approved")
                    Text("Rejected").tag("rejected")
                }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                Button(busy ? "Saving…" : "Save Changes") { Task { await save() } }
                    .disabled(busy || first.isEmpty || last.isEmpty)
            }
            .navigationTitle("Edit Resident")
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            } }
            .onAppear {
                first = resident.firstName
                last = resident.lastName
                status = resident.approval
            }
        }
    }

    @MainActor private func save() async {
        busy = true
        defer { busy = false }
        do {
            _ = try await BoardRosterAPI.call("PATCH", boardId: boardId,
                suffix: "/\(resident.id)", token: token,
                body: ["first_name": first, "last_name": last, "approval_status": status])
            onSaved()
        } catch { self.error = error.localizedDescription }
    }
}

private struct BoardDirectoryImportView: View {
    let boardId: Int
    let token: String
    let community: String
    let onImported: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingPicker = false
    @State private var candidates: [DirectoryCandidate] = []
    @State private var busy = false
    @State private var error = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Upload Resident Directory") {
                    Text(community.isEmpty ? "Your HOA" : community)
                    Text("Select a PDF, CSV, spreadsheet, or image. The document will be analyzed and the extracted residents shown for review before any import.")
                        .font(.caption)
                    Button("Choose Directory File") { showingPicker = true }
                        .disabled(busy)
                    Text("A document may contain private resident information; it is sent to the Clubhouse Links backend and its configured extraction provider.")
                        .font(.caption)
                }
                if !candidates.isEmpty {
                    Section("Review extracted residents (\(candidates.filter(\.selected).count) selected)") {
                        ForEach($candidates) { $candidate in
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Import this resident", isOn: $candidate.selected)
                                TextField("First Name", text: $candidate.firstName)
                                TextField("Last Name", text: $candidate.lastName)
                                TextField("Phone", text: $candidate.phone).keyboardType(.phonePad)
                                TextField("Address", text: $candidate.address)
                            }
                        }
                        Button(busy ? "Importing…" : "Import Selected Residents") {
                            Task { await importSelected() }
                        }
                        .disabled(busy || !candidates.contains(where: \.selected))
                    }
                }
                if busy { ProgressView() }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                if !message.isEmpty { Text(message).foregroundStyle(.green) }
            }
            .navigationTitle("Import Residents")
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            } }
            .fileImporter(isPresented: $showingPicker, allowedContentTypes: [.pdf, .image, .commaSeparatedText, .data]) { result in
                switch result {
                case .success(let url): Task { await extract(url) }
                case .failure(let failure): error = failure.localizedDescription
                }
            }
        }
    }

    @MainActor private func extract(_ url: URL) async {
        busy = true
        error = ""
        message = ""
        defer { busy = false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            guard !data.isEmpty && data.count <= 6 * 1024 * 1024 else {
                throw RosterFailure("The file must be no larger than 6 MB.")
            }
            let response = try await BoardRosterAPI.call("POST", boardId: boardId,
                suffix: "/extract", token: token,
                body: ["filename": url.lastPathComponent,
                       "data_base64": data.base64EncodedString()])
            candidates = (response["residents"] as? [[String: Any]] ?? [])
                .map(DirectoryCandidate.init)
            message = "\(candidates.count) residents extracted. Review every entry before importing."
        } catch { self.error = error.localizedDescription }
    }

    @MainActor private func importSelected() async {
        let selected = candidates.filter(\.selected).map(\.payload)
        guard !selected.isEmpty else { return }
        busy = true
        error = ""
        defer { busy = false }
        do {
            // Preserve the backend's maximum of 100 reviewed records per request.
            let response = try await BoardRosterAPI.call("POST", boardId: boardId,
                suffix: "/import", token: token, body: ["residents": selected])
            let created = response["created"] as? Int ?? response["imported"] as? Int ?? 0
            message = "Import completed. \(created) residents created."
            candidates = []
            onImported()
        } catch { self.error = error.localizedDescription }
    }
}
