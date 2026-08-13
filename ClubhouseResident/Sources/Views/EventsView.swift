import SwiftUI

struct EventsView: View {
    @AppStorage("residentId") private var residentId = 0
    @AppStorage("residentIsSignedUp") private var residentIsSignedUp = false
    @AppStorage("residentDisplayAreaName") private var displayAreaName = ""

    @StateObject private var viewModel = EventsViewModel()


    private var isSignedIn: Bool {
        residentIsSignedUp && residentId > 0
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if isSignedIn {
                        signedInEvents
                    } else {
                        SignedOutEventsPromotion()
                    }
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 110)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                guard isSignedIn else {
                    return
                }

                await viewModel.loadEvents(
                    residentId: residentId
                )
            }
        }
        .task(id: residentId) {
            if isSignedIn {
                await viewModel.loadEvents(
                    residentId: residentId
                )
            } else {
                viewModel.clear()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isSignedIn ? "Events Near You" : "Community Events")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)

            if isSignedIn && !displayAreaName.isEmpty {
                Label(displayAreaName, systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
            } else if !isSignedIn {
                Text("Meet neighbors, local businesses, and future customers.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }


    @ViewBuilder
    private var signedInEvents: some View {
        VStack(alignment: .leading, spacing: 22) {
            ResidentEventsIntroCard()

            EventsCalendarCard(
                events: viewModel.events
            )

            if viewModel.isLoading {
                loadingCard
            }

            if let errorMessage = viewModel.errorMessage {
                eventsUnavailableCard(
                    message: errorMessage
                )
            }

            if !viewModel.events.isEmpty {
                eventsSections
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            .tint(.cyan)

            Text("Loading events for your area...")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func eventsUnavailableCard(
    message: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(
                systemName:
                "arrow.triangle.2.circlepath"
            )
            .font(.title3.bold())
            .foregroundStyle(.orange)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    "Upcoming events are being updated"
                )
                .font(.subheadline.bold())
                .foregroundStyle(.white)

                Text(
                    "Pull down or tap refresh to check again."
                )
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }

            Spacer()

            Button {
                Task {
                    await viewModel.loadEvents(
                        residentId: residentId
                    )
                }
            } label: {
                Image(
                    systemName:
                    "arrow.clockwise"
                )
                .foregroundStyle(.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            .white.opacity(0.06)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var eventsSections: some View {
        VStack(alignment: .leading, spacing: 28) {
            EventSection(
                title: "Current & Upcoming Events",
                icon: "calendar.badge.clock",
                events: viewModel.currentAndUpcomingEvents,
                emptyMessage: "There are no upcoming events scheduled for your area yet."
            )

            EventSection(
                title: "Past Events",
                icon: "clock.arrow.circlepath",
                events: viewModel.pastEvents,
                emptyMessage: "Past community events will appear here."
            )
        }
    }
}
private struct ResidentEventsIntroCard: View {

    private let imageURL = URL(
        string:
        "https://res.cloudinary.com/drna15e8q/image/upload/v1786591993/vendorevents_ypasxe.jpg"
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            AsyncImage(url: imageURL) { phase in
                switch phase {

                case .empty:
                    ZStack {
                        Rectangle()
                        .fill(.black.opacity(0.25))

                        ProgressView()
                        .tint(.cyan)
                    }

                case .success(let image):
                    image
                    .resizable()
                    .scaledToFill()

                case .failure:
                    ZStack {
                        LinearGradient(
                            colors: [
                                .cyan.opacity(0.25),
                                .purple.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(
                            systemName:
                            "calendar.badge.clock"
                        )
                        .font(.system(size: 50))
                        .foregroundStyle(.cyan)
                    }

                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipped()

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Label(
                    "Meet Local Home Service Professionals",
                    systemImage: "person.3.fill"
                )
                .font(.title3.bold())
                .foregroundStyle(.white)

                Text(
                    """
                    Our events are a way for you to meet local home service technicians and contractors face-to-face. Get expert advice, ask questions about your home, and receive individual pricing for your newest projects and repairs.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.78)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text(
                    "Event dates are highlighted on the calendar below."
                )
                .font(.caption.bold())
                .foregroundStyle(.cyan)
            }
            .padding(18)
        }
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
            RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
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
    }
}
// MARK: - Signed-Out Promotional Content

private struct SignedOutEventsPromotion: View {
    private let gold = Color(
        red: 1.0,
        green: 0.76,
        blue: 0.18
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("foodtruck")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Meet the Community")
                .font(.title2.bold())
                .foregroundStyle(.white)

                Text(
                    """
                    Community events give local businesses the opportunity to meet residents face-to-face, build trust, and form relationships with future customers. Participating in neighborhood events is one of the best ways to become a recognized and recommended local vendor.
                    """
                )
                .font(.body)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

                Text(
                    """
                    You can only get on the vendor list by showing up to an event or by completing 10 verified jobs in a neighborhood.
                    """
                )
                .font(.body.bold())
                .foregroundStyle(gold)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Interested in an Upcoming Event?",
                    systemImage: "star.fill"
                )
                .font(.headline)
                .foregroundStyle(gold)

                Text(
                    "If you would like to be a vendor for an upcoming event, go to the Request Service page and submit your information."
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.90))
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        gold.opacity(0.18),
                        .orange.opacity(0.08),
                        .black.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                .stroke(gold, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: gold.opacity(0.65),
                radius: 14
            )
        }
    }
}

// MARK: - Event Sections
private struct EventsCalendarCard: View {

    let events: [NeighborhoodEvent]

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current

    private var monthTitle: String {
        displayedMonth.formatted(
            .dateTime
            .month(.wide)
            .year()
        )
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols

        let first = calendar.firstWeekday - 1

        return Array(
            symbols[first...] +
            symbols[..<first]
        )
    }

    private var days: [Date?] {
        guard
        let monthInterval =
        calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ),
        let firstWeek =
        calendar.dateInterval(
            of: .weekOfMonth,
            for: monthInterval.start
        )
        else {
            return []
        }

        var result: [Date?] = []

        let monthStart = monthInterval.start

        let daysBeforeMonth =
        calendar.dateComponents(
            [.day],
            from: firstWeek.start,
            to: monthStart
        ).day ?? 0

        for _ in 0..<max(0, daysBeforeMonth) {
            result.append(nil)
        }

        let range =
        calendar.range(
            of: .day,
            in: .month,
            for: displayedMonth
        ) ?? 1..<2

        for dayNumber in range {
            if let date = calendar.date(
                bySetting: .day,
                value: dayNumber,
                of: displayedMonth
            ) {
                result.append(date)
            }
        }

        while result.count % 7 != 0 {
            result.append(nil)
        }

        return result
    }

    private func hasEvent(
    on date: Date
    ) -> Bool {
        events.contains { event in
            calendar.isDate(
                event.startsAt,
                inSameDayAs: date
            )
        }
    }

    private func isToday(
    _ date: Date
    ) -> Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {
                Label(
                    "Event Calendar",
                    systemImage: "calendar"
                )
                .font(.title3.bold())
                .foregroundStyle(.white)

                Spacer()

                Button {
                    moveMonth(-1)
                } label: {
                    Image(
                        systemName: "chevron.left"
                    )
                }

                Text(monthTitle)
                .font(.headline.bold())
                .foregroundStyle(.cyan)
                .frame(minWidth: 145)

                Button {
                    moveMonth(1)
                } label: {
                    Image(
                        systemName: "chevron.right"
                    )
                }
            }
            .foregroundStyle(.cyan)

            LazyVGrid(
                columns: Array(
                    repeating:
                    GridItem(
                        .flexible(),
                        spacing: 6
                    ),
                    count: 7
                ),
                spacing: 8
            ) {

                ForEach(
                    Array(
                        weekdaySymbols.enumerated()
                    ),
                    id: \.offset
                ) { _, symbol in

                    Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(
                        .white.opacity(0.55)
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }

                ForEach(
                    Array(days.enumerated()),
                    id: \.offset
                ) { _, date in

                    if let date {

                        let eventDay =
                        hasEvent(on: date)

                        let today =
                        isToday(date)

                        ZStack {

                            if eventDay {
                                Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .yellow,
                                            .orange
                                        ],
                                        startPoint:
                                        .topLeading,
                                        endPoint:
                                        .bottomTrailing
                                    )
                                )
                                .shadow(
                                    color:
                                    .yellow.opacity(
                                        0.45
                                    ),
                                    radius: 6
                                )

                            } else if today {
                                Circle()
                                .stroke(
                                    .cyan,
                                    lineWidth: 2
                                )
                            }

                            Text(
                                "\(calendar.component(.day, from: date))"
                            )
                            .font(
                                .subheadline.bold()
                            )
                            .foregroundStyle(
                                eventDay
                                ? .black
                                : .white
                            )
                        }
                        .frame(height: 42)

                    } else {
                        Color.clear
                        .frame(height: 42)
                    }
                }
            }

            HStack(spacing: 8) {
                Circle()
                .fill(.yellow)
                .frame(
                    width: 10,
                    height: 10
                )

                Text("Scheduled event")
                .font(.caption.bold())
                .foregroundStyle(
                    .white.opacity(0.72)
                )
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
            RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
            .stroke(
                .cyan.opacity(0.55),
                lineWidth: 1
            )
        )
    }

    private func moveMonth(
    _ amount: Int
    ) {
        guard let newMonth =
        calendar.date(
            byAdding: .month,
            value: amount,
            to: displayedMonth
        )
        else {
            return
        }

        withAnimation(.easeInOut) {
            displayedMonth = newMonth
        }
    }
}

private struct EventSection: View {
    let title: String
    let icon: String
    let events: [NeighborhoodEvent]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
            .font(.title3.bold())
            .foregroundStyle(.white)

            if events.isEmpty {
                Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(events) { event in
                    NeighborhoodEventCard(event: event)
                }
            }
        }
    }
}

// MARK: - Event Card

private struct NeighborhoodEventCard: View {
    let event: NeighborhoodEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                    if let signupLabel = event.signupLabel,
                    !signupLabel.isEmpty {
                        Text(signupLabel.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                        .tracking(0.5)
                    }
                }

                Spacer()

                EventStatusBadge(event: event)
            }

            Divider()
            .overlay(.white.opacity(0.15))

            if let neighborhood = event.neighborhoodLine {
                EventDetailRow(
                    icon: "mappin.and.ellipse",
                    label: "Neighborhood",
                    value: neighborhood
                )
            }

            if let address = event.address,
            !address.isEmpty {
                EventDetailRow(
                    icon: "house",
                    label: "Address",
                    value: address
                )
            }

            EventDetailRow(
                icon: "calendar",
                label: "Date",
                value: event.formattedDate
            )

            EventDetailRow(
                icon: "clock",
                label: "Time",
                value: event.formattedTime
            )

            if let description = event.eventDescription,
            !description.isEmpty {
                Text(description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(event.isPast ? 0.05 : 0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
            .stroke(
                LinearGradient(
                    colors: event.isPast
                    ? [.white.opacity(0.25), .purple.opacity(0.45)]
                    : [.cyan, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(event.isPast ? 0.82 : 1)
    }
}

private struct EventStatusBadge: View {
    let event: NeighborhoodEvent

    var body: some View {
        Text(event.statusText)
        .font(.caption2.bold())
        .foregroundStyle(event.statusForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(event.statusBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
            .stroke(
                event.statusForeground.opacity(0.45),
                lineWidth: 1
            )
        )
    }
}

// MARK: - Event Detail Row

struct EventDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
            .foregroundStyle(.cyan)
            .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(0.5)

                Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Event Model

struct NeighborhoodEvent: Identifiable, Decodable {
    let id: Int
    let title: String
    let neighborhoodName: String?
    let city: String?
    let state: String?
    let address: String?
    let startsAt: Date
    let endsAt: Date?
    let status: String?
    let signupLabel: String?
    let eventDescription: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case neighborhoodName = "neighborhood_name"
        case city
        case state
        case address
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case status
        case signupLabel = "signup_label"
        case eventDescription = "description"
    }

    var isPast: Bool {
        (endsAt ?? startsAt) < Date()
    }

    var isHappeningNow: Bool {
        let currentDate = Date()
        let endingDate = endsAt ?? startsAt

        return startsAt <= currentDate &&
        endingDate >= currentDate
    }

    var neighborhoodLine: String? {
        var components: [String] = []

        if let neighborhoodName,
        !neighborhoodName.isEmpty {
            components.append(neighborhoodName)
        }

        let cityAndState = [city, state]
        .compactMap { value in
            guard let value,
            !value.isEmpty else {
                return nil
            }

            return value
        }
        .joined(separator: ", ")

        if !cityAndState.isEmpty {
            components.append(cityAndState)
        }

        guard !components.isEmpty else {
            return nil
        }

        return components.joined(separator: " — ")
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: startsAt)
    }

    var formattedTime: String {
        let start = Self.timeFormatter.string(from: startsAt)

        guard let endsAt else {
            return start
        }

        let end = Self.timeFormatter.string(from: endsAt)
        return "\(start) – \(end)"
    }

    var statusText: String {
        if isHappeningNow {
            return "Happening Now"
        }

        if isPast {
            return "Completed"
        }

        if let status,
        !status.isEmpty {
            return status.capitalized
        }

        return "Scheduled"
    }

    var statusForeground: Color {
        if isHappeningNow {
            return Color(
                red: 0,
                green: 1,
                blue: 0.63
            )
        }

        if isPast {
            return .white.opacity(0.65)
        }

        return .cyan
    }

    var statusBackground: Color {
        if isHappeningNow {
            return .green.opacity(0.16)
        }

        if isPast {
            return .white.opacity(0.08)
        }

        return .cyan.opacity(0.12)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

// MARK: - View Model

@MainActor
final class EventsViewModel: ObservableObject {
    @Published private(set) var events: [NeighborhoodEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service = NeighborhoodEventsService()

    var currentAndUpcomingEvents: [NeighborhoodEvent] {
        events
        .filter { !$0.isPast }
        .sorted { $0.startsAt < $1.startsAt }
    }

    var pastEvents: [NeighborhoodEvent] {
        events
        .filter(\.isPast)
        .sorted { $0.startsAt > $1.startsAt }
    }

    func loadEvents(residentId: Int) async {
        guard residentId > 0 else {
            clear()
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            events = try await service.fetchEvents(
                residentId: residentId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        events = []
        errorMessage = nil
        isLoading = false
    }
}

// MARK: - API Service

private struct NeighborhoodEventsService {
    private let baseURL = URL(
        string: "https://crm-function-app-5d4de511071d.herokuapp.com"
    )!

    func fetchEvents(
    residentId: Int
    ) async throws -> [NeighborhoodEvent] {
        let url = baseURL.appendingPathComponent(
            "server/resident_function/api/residents/events/\(residentId)"
        )

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventsAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EventsAPIError.httpError(
                statusCode: httpResponse.statusCode
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

            if let date = fractionalFormatter.date(from: value) {
                return date
            }

            let standardFormatter = ISO8601DateFormatter()
            standardFormatter.formatOptions = [
                .withInternetDateTime
            ]

            if let date = standardFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid event date: \(value)"
            )
        }

        if let envelope = try? decoder.decode(
            NeighborhoodEventsEnvelope.self,
            from: data
        ) {
            return envelope.events
        }

        return try decoder.decode(
            [NeighborhoodEvent].self,
            from: data
        )
    }
}

private struct NeighborhoodEventsEnvelope: Decodable {
    let events: [NeighborhoodEvent]
}

private enum EventsAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."

        case .httpError(let statusCode):
            return "The events request failed with status \(statusCode)."
        }
    }
}