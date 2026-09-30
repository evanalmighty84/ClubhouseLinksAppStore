import SwiftUI

// MARK: - HOA Announcement Model

struct NeighborhoodAnnouncement: Identifiable, Decodable {
    let id: Int
    let title: String
    let body: String
    let imageURL: String?
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case imageURL = "image_url"
        case publishedAt = "published_at"
    }
}


// MARK: - Combined Update Item

private struct NeighborhoodUpdateItem: Identifiable {

    enum Kind {
        case event
        case announcement
    }

    let id: String
    let kind: Kind
    let title: String
    let body: String
    let imageURL: String?
    let dateText: String?
    let statusText: String?

    static func from(
    event: NeighborhoodEvent
    ) -> NeighborhoodUpdateItem {

        NeighborhoodUpdateItem(
            id: "event-\(event.id)",
            kind: .event,
            title: event.title,
            body: event.eventDescription ??
            "View details for this neighborhood event.",
            imageURL: event.imageURL,
            dateText:
            "\(event.formattedDate) • \(event.formattedTime)",
            statusText: event.statusText
        )
    }

    static func from(
    announcement: NeighborhoodAnnouncement
    ) -> NeighborhoodUpdateItem {

        NeighborhoodUpdateItem(
            id: "announcement-\(announcement.id)",
            kind: .announcement,
            title: announcement.title,
            body: announcement.body,
            imageURL: announcement.imageURL,
            dateText: announcement.publishedAt.map {
                announcementDateFormatter.string(
                    from: $0
                )
            },
            statusText: nil
        )
    }
}


// MARK: - Neighborhood Updates Carousel

struct NeighborhoodUpdatesCarousel: View {

    let residentId: Int
    let neighborhoodName: String

    @Binding
    var showingAccountSettings: Bool

    @AppStorage("residentSelectedTab")
    private var selectedTab = "home"

    @StateObject

    @State
    private var selectedUpdatePage = 0
    private var viewModel =
    NeighborhoodUpdatesViewModel()

    private var cleanNeighborhoodName: String {
        let clean =
        neighborhoodName
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if clean.isEmpty ||
        clean == "Area not set" {

            return "Your Neighborhood"
        }

        return clean
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            updatesHeader

            updatesCarousel
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(0.10),
                    .purple.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 26
            )
            .stroke(
                .cyan.opacity(0.45),
                lineWidth: 1
            )
        )
        .shadow(
            color: .cyan.opacity(0.12),
            radius: 10
        )
        .task(id: residentId) {

            await viewModel.load(
                residentId: residentId
            )
        }
        .task(
            id:
            "neighborhood-intro-\(residentId)"
        ) {

            /*
             * Every time we move to a different
             * resident, begin with the bird
             * announcement slide.
             */
            selectedUpdatePage = 0

            do {

                try await Task.sleep(
                    nanoseconds:
                    7_000_000_000
                )

            } catch {

                return
            }


            /*
             * Only auto-advance if the resident
             * has not already swiped away from
             * the intro manually.
             */
            guard selectedUpdatePage == 0
            else {
                return
            }

            withAnimation(
                .easeInOut(
                    duration: 0.45
                )
            ) {

                selectedUpdatePage = 1
            }
        }
    }


    // MARK: - Header

    private var updatesHeader: some View {

        HStack(
            alignment: .center,
            spacing: 12
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Label(
                    "NEIGHBORHOOD UPDATES",
                    systemImage:
                    "megaphone.fill"
                )
                .font(.caption.bold())
                .tracking(1.1)
                .foregroundStyle(.cyan)

                Text(
                    cleanNeighborhoodName
                )
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            }

            Spacer()

            Button {

                showingAccountSettings =
                true

            } label: {

                VStack(spacing: 4) {

                    Image(
                        systemName:
                        "slider.horizontal.3"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )

                    Text("Account")
                    .font(.caption2.bold())
                }
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .vertical,
                    9
                )
                .background(
                    LinearGradient(
                        colors: [
                            .cyan.opacity(0.30),
                            .purple.opacity(0.45)
                        ],
                        startPoint:
                        .topLeading,
                        endPoint:
                        .bottomTrailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .stroke(
                        .cyan.opacity(0.65),
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }


    // MARK: - Carousel

    // MARK: - Carousel

    private var updatesCarousel: some View {

        TabView(
            selection:
            $selectedUpdatePage
        ) {

            /*
             * Slide 0 always appears first.
             */
            announcementIntroSlide
            .tag(0)


            /*
             * Slide 1 becomes whichever state
             * the feed is currently in:
             *
             * loading
             * no updates
             * or the first real update.
             */
            if viewModel.isLoading &&
            viewModel.items.isEmpty {

                loadingCard
                .tag(1)

            } else if viewModel.items.isEmpty {

                emptyCard
                .tag(1)

            } else {

                ForEach(
                    Array(
                        viewModel.items
                        .enumerated()
                    ),
                    id: \.element.id
                ) { index, item in

                    updateCard(item)
                    .padding(
                        .horizontal,
                        2
                    )
                    .tag(
                        index + 1
                    )
                }
            }
        }
        .frame(height: 235)
        .tabViewStyle(
            PageTabViewStyle(
                indexDisplayMode:
                .automatic
            )
        )
    }
    // MARK: - Announcement Intro Slide

    private var announcementIntroSlide:
    some View {

        LoopingBirdVideoView(
            resourceName:
            "clubhouse_bird_announcements",
            fileExtension:
            "mp4"
        )
        .frame(
            maxWidth:
            .infinity
        )
        .frame(
            height:
            215
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                .cyan.opacity(0.40),
                lineWidth: 1
            )
        )
        .allowsHitTesting(false)
    }


    // MARK: - Update Card

    @ViewBuilder
    private func updateCard(
    _ item: NeighborhoodUpdateItem
    ) -> some View {

        Button {

            /*
             * Events open the existing
             * Events tab.
             *
             * Announcements remain visible
             * directly in this carousel.
             */
            if item.kind == .event {
                selectedTab = "events"
            }

        } label: {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack {

                    Label(
                        item.kind == .event
                        ? "EVENT"
                        : "ANNOUNCEMENT",
                        systemImage:
                        item.kind == .event
                        ? "calendar"
                        : "megaphone.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(
                        item.kind == .event
                        ? .cyan
                        : .orange
                    )

                    Spacer()

                    if let status =
                    item.statusText,
                    !status.isEmpty {

                        Text(status)
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.75
                            )
                        )
                    }
                }

                HStack(
                    alignment: .top,
                    spacing: 12
                ) {

                    if let imageURL =
                    item.imageURL,
                    !imageURL.isEmpty,
                    let url =
                    URL(
                        string: imageURL
                    ) {

                        AsyncImage(
                            url: url
                        ) { phase in

                            switch phase {

                            case .empty:

                                ZStack {
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                    .fill(
                                        .black.opacity(
                                            0.24
                                        )
                                    )

                                    ProgressView()
                                    .tint(.cyan)
                                }

                            case .success(
                            let image
                            ):

                                image
                                .resizable()
                                .scaledToFill()

                            case .failure:

                                ZStack {
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                    .fill(
                                        .black.opacity(
                                            0.24
                                        )
                                    )

                                    Image(
                                        systemName:
                                        "photo"
                                    )
                                    .foregroundStyle(
                                        .white.opacity(
                                            0.45
                                        )
                                    )
                                }

                            @unknown default:

                                EmptyView()
                            }
                        }
                        .frame(
                            width: 95,
                            height: 105
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 7
                    ) {

                        Text(item.title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(
                            .leading
                        )
                        .lineLimit(2)

                        if let dateText =
                        item.dateText,
                        !dateText.isEmpty {

                            Text(dateText)
                            .font(.caption.bold())
                            .foregroundStyle(
                                .cyan.opacity(
                                    0.90
                                )
                            )
                            .lineLimit(2)
                        }

                        Text(item.body)
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(
                                0.72
                            )
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                        .lineLimit(3)
                    }

                    Spacer(
                        minLength: 0
                    )
                }

                if item.kind == .event {

                    HStack {

                        Spacer()

                        Label(
                            "View Event",
                            systemImage:
                            "chevron.right"
                        )
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                    }
                }
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                .black.opacity(0.22)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 20
                )
                .stroke(
                    item.kind == .event
                    ? .cyan.opacity(0.40)
                    : .orange.opacity(0.40),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: - Loading

    private var loadingCard: some View {

        VStack(spacing: 12) {

            ProgressView()
            .tint(.cyan)

            Text(
                "Loading neighborhood updates..."
            )
            .font(.subheadline.bold())
            .foregroundStyle(
                .white.opacity(0.72)
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 180)
        .background(
            .black.opacity(0.18)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }


    // MARK: - Empty State

    private var emptyCard: some View {

        VStack(spacing: 10) {

            Image(
                systemName:
                "house.and.flag"
            )
            .font(
                .system(
                    size: 30
                )
            )
            .foregroundStyle(.cyan)

            Text(
                "No neighborhood updates yet"
            )
            .font(.headline.bold())
            .foregroundStyle(.white)

            Text(
                "Events and HOA announcements will appear here."
            )
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.68)
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 180)
        .background(
            .black.opacity(0.18)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}


// MARK: - View Model

@MainActor
private final class NeighborhoodUpdatesViewModel:
ObservableObject {

    @Published
    private(set)
    var items:
    [NeighborhoodUpdateItem] = []

    @Published
    private(set)
    var isLoading = false

    private let service =
    NeighborhoodUpdatesService()

    func load(
    residentId: Int
    ) async {

        guard residentId > 0
        else {

            items = []
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        var events:
        [NeighborhoodEvent] = []

        var announcements:
        [NeighborhoodAnnouncement] = []


        // Existing production events endpoint.

        do {

            events =
            try await service
            .fetchEvents(
                residentId:
                residentId
            )

        } catch {

            print(
                "[Neighborhood Updates] Event load failed:",
                error.localizedDescription
            )
        }


        /*
         * Announcements endpoint will return
         * an empty array until we add the
         * backend route.
         */

        do {

            announcements =
            try await service
            .fetchAnnouncements(
                residentId:
                residentId
            )

        } catch {

            print(
                "[Neighborhood Updates] Announcement load failed:",
                error.localizedDescription
            )
        }


        let eventItems =
        events
        .filter {
            !$0.isPast
        }
        .sorted {
            $0.startsAt <
            $1.startsAt
        }
        .map {
            NeighborhoodUpdateItem
            .from(
                event: $0
            )
        }


        let announcementItems =
        announcements
        .sorted {

            (
            $0.publishedAt ??
            .distantPast
            )
            >
            (
            $1.publishedAt ??
            .distantPast
            )
        }
        .map {

            NeighborhoodUpdateItem
            .from(
                announcement: $0
            )
        }


        items =
        interleave(
            announcements:
            announcementItems,
            events:
            eventItems
        )
    }


    private func interleave(
    announcements:
    [NeighborhoodUpdateItem],
    events:
    [NeighborhoodUpdateItem]
    ) -> [NeighborhoodUpdateItem] {

        var result:
        [NeighborhoodUpdateItem] = []

        let largestCount =
        max(
            announcements.count,
            events.count
        )

        guard largestCount > 0
        else {
            return []
        }

        for index in
        0..<largestCount {

            if index <
            announcements.count {

                result.append(
                    announcements[index]
                )
            }

            if index <
            events.count {

                result.append(
                    events[index]
                )
            }
        }

        return Array(
            result.prefix(10)
        )
    }
}


// MARK: - API

private struct NeighborhoodUpdatesService {

    private let baseURL =
    URL(
        string:
        "https://crm-function-app-5d4de511071d.herokuapp.com"
    )!


    // MARK: Events

    func fetchEvents(
    residentId: Int
    ) async throws
    -> [NeighborhoodEvent] {

        let url =
        baseURL
        .appendingPathComponent(
            "server/resident_function/api/residents/events/\(residentId)"
        )

        var request =
        URLRequest(
            url: url
        )

        request.httpMethod = "GET"

        request.timeoutInterval = 30

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Accept"
        )


        let (data, response) =
        try await URLSession
        .shared
        .data(
            for: request
        )


        guard let httpResponse =
        response
        as? HTTPURLResponse
        else {

            throw NeighborhoodUpdatesError
            .invalidResponse
        }


        guard (200...299)
        .contains(
            httpResponse
            .statusCode
        )
        else {

            throw NeighborhoodUpdatesError
            .server(
                "Events request failed with status \(httpResponse.statusCode)."
            )
        }


        let decoder =
        neighborhoodUpdatesDecoder()


        if let envelope =
        try? decoder
        .decode(
            HomeEventsEnvelope.self,
            from: data
        ) {

            return envelope.events ?? []
        }


        return try decoder
        .decode(
            [NeighborhoodEvent].self,
            from: data
        )
    }


    // MARK: Announcements

    func fetchAnnouncements(
    residentId: Int
    ) async throws
    -> [NeighborhoodAnnouncement] {

        let url =
        baseURL
        .appendingPathComponent(
            "server/resident_function/api/residents/announcements/\(residentId)"
        )

        var request =
        URLRequest(
            url: url
        )

        request.httpMethod = "GET"

        request.timeoutInterval = 30

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Accept"
        )


        let (data, response) =
        try await URLSession
        .shared
        .data(
            for: request
        )


        guard let httpResponse =
        response
        as? HTTPURLResponse
        else {

            throw NeighborhoodUpdatesError
            .invalidResponse
        }


        /*
         * Until this route exists,
         * a 404 simply means there are
         * no announcements.
         */

        if httpResponse.statusCode == 404 {
            return []
        }


        guard (200...299)
        .contains(
            httpResponse
            .statusCode
        )
        else {

            throw NeighborhoodUpdatesError
            .server(
                "Announcements request failed with status \(httpResponse.statusCode)."
            )
        }


        let decoder =
        neighborhoodUpdatesDecoder()


        if let envelope =
        try? decoder
        .decode(
            HomeAnnouncementsEnvelope.self,
            from: data
        ) {

            return envelope
            .announcements ??
            []
        }


        return try decoder
        .decode(
            [NeighborhoodAnnouncement].self,
            from: data
        )
    }
}


// MARK: - API Envelopes

private struct HomeEventsEnvelope:
Decodable {

    let events:
    [NeighborhoodEvent]?
}


private struct HomeAnnouncementsEnvelope:
Decodable {

    let announcements:
    [NeighborhoodAnnouncement]?
}


// MARK: - Date Decoder

private func neighborhoodUpdatesDecoder()
-> JSONDecoder {

    let decoder =
    JSONDecoder()

    decoder.dateDecodingStrategy =
    .custom {
        decoder in

        let container =
        try decoder
        .singleValueContainer()

        let value =
        try container
        .decode(
            String.self
        )


        let fractionalFormatter =
        ISO8601DateFormatter()

        fractionalFormatter
        .formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date =
        fractionalFormatter
        .date(
            from: value
        ) {

            return date
        }


        let standardFormatter =
        ISO8601DateFormatter()

        standardFormatter
        .formatOptions = [
            .withInternetDateTime
        ]

        if let date =
        standardFormatter
        .date(
            from: value
        ) {

            return date
        }


        throw DecodingError
        .dataCorruptedError(
            in: container,
            debugDescription:
            "Invalid update date: \(value)"
        )
    }

    return decoder
}


// MARK: - Announcement Date

private let announcementDateFormatter:
DateFormatter = {

    let formatter =
    DateFormatter()

    formatter.dateFormat =
    "MMM d, yyyy"

    return formatter
}()


// MARK: - Error

private enum NeighborhoodUpdatesError:
LocalizedError {

    case invalidResponse
    case server(String)

    var errorDescription:
    String? {

        switch self {

        case .invalidResponse:

            return "The server returned an invalid response."

        case .server(
        let message
        ):

            return message
        }
    }
}