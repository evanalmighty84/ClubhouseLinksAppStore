import SwiftUI

// MARK: - HOA Announcement Model

struct NeighborhoodAnnouncement:
Identifiable,
Decodable {

    let id: Int
    let title: String
    let body: String
    let imageURL: String?
    let publishedAt: Date?

    enum CodingKeys:
    String,
    CodingKey {

        case id
        case title
        case body

        case imageURL =
        "image_url"

        case publishedAt =
        "published_at"
    }
}


// MARK: - Update Item

private struct NeighborhoodUpdateItem:
Identifiable {

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
            id:
            "event-\(event.id)",
            kind:
            .event,
            title:
            event.title,
            body:
            event.eventDescription ??
            "View details for this neighborhood event.",
            imageURL:
            event.imageURL,
            dateText:
            "\(event.formattedDate) • \(event.formattedTime)",
            statusText:
            event.statusText
        )
    }

    static func from(
    announcement:
    NeighborhoodAnnouncement
    ) -> NeighborhoodUpdateItem {

        NeighborhoodUpdateItem(
            id:
            "announcement-\(announcement.id)",
            kind:
            .announcement,
            title:
            announcement.title,
            body:
            announcement.body,
            imageURL:
            announcement.imageURL,
            dateText:
            announcement.publishedAt.map {
                announcementDateFormatter
                .string(from: $0)
            },
            statusText:
            nil
        )
    }
}


// MARK: - Carousel

struct NeighborhoodUpdatesCarousel:
View {

    let residentId: Int
    let neighborhoodName: String

    @AppStorage("residentSelectedTab")
    private var selectedTab =
    "home"

    @StateObject
    private var viewModel =
    NeighborhoodUpdatesViewModel()

    private var cleanNeighborhoodName:
    String {

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

    var body:
    some View {

        VStack(
            alignment:
            .leading,
            spacing:
            12
        ) {

            HStack {

                VStack(
                    alignment:
                    .leading,
                    spacing:
                    3
                ) {

                    Text(
                        "NEIGHBORHOOD UPDATES"
                    )
                    .font(
                        .caption.bold()
                    )
                    .tracking(1.1)
                    .foregroundStyle(
                        .cyan
                    )

                    Text(
                        cleanNeighborhoodName
                    )
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        .white
                    )
                }

                Spacer()

                Image(
                    systemName:
                    "megaphone.fill"
                )
                .font(
                    .title2
                )
                .foregroundStyle(
                    .orange
                )
            }


            if viewModel.isLoading &&
            viewModel.items.isEmpty {

                loadingCard

            } else if
            viewModel.items.isEmpty {

                emptyCard

            } else {

                TabView {

                    ForEach(
                        viewModel.items
                    ) { item in

                        updateCard(
                            item
                        )
                        .padding(
                            .horizontal,
                            2
                        )
                    }
                }
                .frame(
                    height:
                    235
                )
                .tabViewStyle(
                    .page(
                        indexDisplayMode:
                        .automatic
                    )
                )
            }
        }
        .padding(
            18
        )
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(
                        0.10
                    ),
                    .purple.opacity(
                        0.18
                    )
                ],
                startPoint:
                .topLeading,
                endPoint:
                .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                26
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius:
                26
            )
            .stroke(
                .cyan.opacity(
                    0.45
                ),
                lineWidth:
                1
            )
        )
        .task(
            id:
            residentId
        ) {

            await viewModel.load(
                residentId:
                residentId
            )
        }
    }


    // MARK: - Update Card

    @ViewBuilder
    private func updateCard(
    _ item:
    NeighborhoodUpdateItem
    ) -> some View {

        Button {

            /*
             * Events open the existing
             * Events tab.
             *
             * Announcements remain on the
             * home feed for now.
             */
            if item.kind ==
            .event {

                selectedTab =
                "events"
            }

        } label: {

            VStack(
                alignment:
                .leading,
                spacing:
                12
            ) {

                HStack {

                    Label(
                        item.kind ==
                        .event
                        ? "EVENT"
                        : "ANNOUNCEMENT",
                        systemImage:
                        item.kind ==
                        .event
                        ? "calendar"
                        : "megaphone.fill"
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        item.kind ==
                        .event
                        ? .cyan
                        : .orange
                    )

                    Spacer()

                    if let status =
                    item.statusText,
                    !status.isEmpty {

                        Text(
                            status
                        )
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.78
                            )
                        )
                    }
                }


                HStack(
                    alignment:
                    .top,
                    spacing:
                    12
                ) {

                    if let imageURL =
                    item.imageURL,
                    !imageURL.isEmpty,
                    let url =
                    URL(
                        string:
                        imageURL
                    ) {

                        AsyncImage(
                            url:
                            url
                        ) { image in

                            image
                            .resizable()
                            .scaledToFill()

                        } placeholder: {

                            ZStack {

                                RoundedRectangle(
                                    cornerRadius:
                                    14
                                )
                                .fill(
                                    .black.opacity(
                                        0.24
                                    )
                                )

                                ProgressView()
                                .tint(
                                    .cyan
                                )
                            }
                        }
                        .frame(
                            width:
                            95,
                            height:
                            105
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                14
                            )
                        )
                    }


                    VStack(
                        alignment:
                        .leading,
                        spacing:
                        7
                    ) {

                        Text(
                            item.title
                        )
                        .font(
                            .headline.bold()
                        )
                        .foregroundStyle(
                            .white
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                        .lineLimit(
                            2
                        )


                        if let dateText =
                        item.dateText,
                        !dateText.isEmpty {

                            Text(
                                dateText
                            )
                            .font(
                                .caption.bold()
                            )
                            .foregroundStyle(
                                .cyan.opacity(
                                    0.9
                                )
                            )
                            .lineLimit(
                                2
                            )
                        }


                        Text(
                            item.body
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.72
                            )
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                        .lineLimit(
                            3
                        )
                    }

                    Spacer(
                        minLength:
                        0
                    )
                }


                if item.kind ==
                .event {

                    HStack {

                        Spacer()

                        Label(
                            "View Event",
                            systemImage:
                            "chevron.right"
                        )
                        .font(
                            .caption.bold()
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }
                }
            }
            .padding(
                16
            )
            .frame(
                maxWidth:
                .infinity,
                alignment:
                .leading
            )
            .background(
                .black.opacity(
                    0.22
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                    20
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius:
                    20
                )
                .stroke(
                    item.kind ==
                    .event
                    ? .cyan.opacity(
                        0.40
                    )
                    : .orange.opacity(
                        0.40
                    ),
                    lineWidth:
                    1
                )
            )
        }
        .buttonStyle(
            .plain
        )
    }


    private var loadingCard:
    some View {

        VStack(
            spacing:
            12
        ) {

            ProgressView()
            .tint(
                .cyan
            )

            Text(
                "Loading neighborhood updates..."
            )
            .font(
                .subheadline.bold()
            )
            .foregroundStyle(
                .white.opacity(
                    0.72
                )
            )
        }
        .frame(
            maxWidth:
            .infinity
        )
        .frame(
            height:
            180
        )
        .background(
            .black.opacity(
                0.18
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                20
            )
        )
    }


    private var emptyCard:
    some View {

        VStack(
            spacing:
            10
        ) {

            Image(
                systemName:
                "house.and.flag"
            )
            .font(
                .system(
                    size:
                    30
                )
            )
            .foregroundStyle(
                .cyan
            )

            Text(
                "No neighborhood updates yet"
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .white
            )

            Text(
                "Events and HOA announcements will appear here."
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .white.opacity(
                    0.68
                )
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth:
            .infinity
        )
        .frame(
            height:
            180
        )
        .background(
            .black.opacity(
                0.18
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                20
            )
        )
    }
}


// MARK: - View Model

@MainActor
private final class
NeighborhoodUpdatesViewModel:
ObservableObject {

    @Published
    private(set)
    var items:
    [NeighborhoodUpdateItem] = []

    @Published
    private(set)
    var isLoading =
    false

    private let service =
    NeighborhoodUpdatesService()

    func load(
    residentId:
    Int
    ) async {

        guard residentId > 0
        else {

            items = []

            return
        }

        isLoading =
        true

        defer {

            isLoading =
            false
        }


        var events:
        [NeighborhoodEvent] = []

        var announcements:
        [NeighborhoodAnnouncement] = []


        /*
         * Events already exist in production.
         */
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
         * This endpoint is the next backend
         * piece we will add.
         *
         * A 404 is intentionally treated as
         * no announcements so the carousel
         * works immediately with events.
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
                event:
                $0
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
                announcement:
                $0
            )
        }


        /*
         * Alternate announcements and events
         * so one type does not bury the other.
         */
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
                    announcements[
                        index
                    ]
                )
            }

            if index <
            events.count {

                result.append(
                    events[
                        index
                    ]
                )
            }
        }

        return Array(
            result.prefix(
                10
            )
        )
    }
}


// MARK: - API

private struct
NeighborhoodUpdatesService {

    private let baseURL =
    URL(
        string:
        "https://crm-function-app-5d4de511071d.herokuapp.com"
    )!

    func fetchEvents(
    residentId:
    Int
    ) async throws
    -> [NeighborhoodEvent] {

        let url =
        baseURL
        .appendingPathComponent(
            "server/resident_function/api/residents/events/\(residentId)"
        )

        let (data, response) =
        try await URLSession
        .shared
        .data(
            from:
            url
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
            from:
            data
        ) {

            return envelope.events ??
            []
        }

        return try decoder
        .decode(
            [NeighborhoodEvent].self,
            from:
            data
        )
    }


    func fetchAnnouncements(
    residentId:
    Int
    ) async throws
    -> [NeighborhoodAnnouncement] {

        let url =
        baseURL
        .appendingPathComponent(
            "server/resident_function/api/residents/announcements/\(residentId)"
        )

        let (data, response) =
        try await URLSession
        .shared
        .data(
            from:
            url
        )

        guard let httpResponse =
        response
        as? HTTPURLResponse
        else {
            throw NeighborhoodUpdatesError
            .invalidResponse
        }


        /*
         * Until we add the backend route,
         * simply behave as though there are
         * no announcements.
         */
        if httpResponse.statusCode ==
        404 {

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
            from:
            data
        ) {

            return envelope
            .announcements ??
            []
        }

        return try decoder
        .decode(
            [NeighborhoodAnnouncement].self,
            from:
            data
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

    decoder
    .dateDecodingStrategy =
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
            from:
            value
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
            from:
            value
        ) {

            return date
        }


        throw DecodingError
        .dataCorruptedError(
            in:
            container,
            debugDescription:
            "Invalid update date: \(value)"
        )
    }

    return decoder
}


private let announcementDateFormatter:
DateFormatter = {

    let formatter =
    DateFormatter()

    formatter.dateFormat =
    "MMM d, yyyy"

    return formatter
}()


private enum NeighborhoodUpdatesError:
LocalizedError {

    case invalidResponse
    case server(String)

    var errorDescription:
    String? {

        switch self {

        case .invalidResponse:

            return
            "The server returned an invalid response."

        case .server(
        let message
        ):

            return message
        }
    }
}