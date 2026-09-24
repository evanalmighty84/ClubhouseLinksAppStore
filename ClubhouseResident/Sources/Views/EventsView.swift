import SwiftUI
import PhotosUI
import UIKit

struct EventsView: View {

    @AppStorage("residentId")
    private var residentId = 0

    @AppStorage("residentIsSignedUp")
    private var residentIsSignedUp = false

    @AppStorage("residentDisplayAreaName")
    private var displayAreaName = ""

    @AppStorage("hoaResidentPreviewMode")
    private var hoaResidentPreviewMode = false

    @AppStorage("residentNeighborhoodId")
    private var residentNeighborhoodId = 0

    @AppStorage("residentNeighborhoodName")
    private var residentNeighborhoodName = ""


    @AppStorage("residentBoardOfDirectors")
    private var residentBoardOfDirectors = false


    @StateObject
    private var viewModel = EventsViewModel()

    @State
    private var hasResolvedEventRole = false

    @State
    private var isResolvingEventRole = false

    @State
    private var showingCreateEvent = false

    private var isSignedIn: Bool {
        residentIsSignedUp &&
        residentId > 0
    }

    private var isHoaBoardMember: Bool {
        residentId > 0 &&
        residentBoardOfDirectors
    }

    private var isHoaBoardViewActive: Bool {
        isHoaBoardMember &&
        !hoaResidentPreviewMode
    }



    private var effectiveNeighborhoodName: String {

        let neighborhoodName =
        residentNeighborhoodName
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !neighborhoodName.isEmpty {
            return neighborhoodName
        }

        let areaName =
        displayAreaName
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !areaName.isEmpty {
            return areaName
        }

        return "Your Neighborhood"
    }

    var body: some View {

        NeonBackground {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    if isSignedIn &&
                    !hasResolvedEventRole {

                        roleLoadingCard

    } else if isHoaBoardViewActive {

        hoaBoardEventsContent

    } else {

                        residentEventsContent
                    }
                }
                .frame(
                    maxWidth: 760,
                    alignment: .leading
                )
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 110)
                .frame(
                    maxWidth: .infinity
                )
            }
            .refreshable {

                guard isSignedIn else {
                    return
                }

                await refreshEventRole()

                await viewModel.loadEvents(
                    residentId:
                    residentId,
                    isHoaBoardMember:
                    isHoaBoardViewActive
                )
            }
        }
        .task(id: residentId) {

            guard isSignedIn else {

                hasResolvedEventRole =
                true

                viewModel.clear()

                return
            }

            hasResolvedEventRole =
            false

            await refreshEventRole()

            await viewModel.loadEvents(
                residentId:
                residentId,
                isHoaBoardMember:
                isHoaBoardViewActive
            )
        }
        .sheet(
            isPresented:
            $showingCreateEvent
        ) {

            CreateNeighborhoodEventView(
                residentId:
                residentId,
                neighborhoodName:
                effectiveNeighborhoodName
            ) {

                showingCreateEvent =
                false

                Task {

                    await viewModel.loadEvents(
                        residentId:
                        residentId,
                        isHoaBoardMember:
                        isHoaBoardViewActive
                    )
                }
            }
            .presentationDetents([
                .large
            ])
        }
    }

    // MARK: - Resident Content

    @ViewBuilder
    private var residentEventsContent:
    some View {

        header

        if isSignedIn {

            signedInEvents

        } else {

            SignedOutEventsPromotion()
        }
    }

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(
                isSignedIn
                ? "Events Near You"
                : "Community Events"
            )
            .font(
                .largeTitle.bold()
            )
            .foregroundStyle(
                .white
            )

            if isSignedIn {

                Label(
                    effectiveNeighborhoodName,
                    systemImage:
                    "mappin.and.ellipse"
                )
                .font(
                    .subheadline
                    .weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .cyan
                )

            } else {

                Text(
                    "Meet neighbors, local businesses, and future customers."
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.7
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var signedInEvents:
    some View {

        VStack(
            alignment: .leading,
            spacing: 22
        ) {

            ResidentEventsIntroCard()
            if isHoaBoardMember &&
            hoaResidentPreviewMode {

                Button {

                    switchToBoardView()

                } label: {

                    HStack(
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                            "house.and.flag.fill"
                        )

                        VStack(
                            alignment:
                            .leading,
                            spacing: 3
                        ) {

                            Text(
                                "Return to HOA Board View"
                            )
                            .font(
                                .headline.bold()
                            )

                            Text(
                                "Manage \(effectiveNeighborhoodName) events"
                            )
                            .font(
                                .caption
                            )
                            .opacity(
                                0.78
                            )
                        }

                        Spacer()

                        Image(
                            systemName:
                            "arrow.left"
                        )
                    }
                    .foregroundStyle(
                        .black
                    )
                    .padding()
                    .frame(
                        maxWidth:
                        .infinity
                    )
                    .background(
                        LinearGradient(
                            colors: [
                                .cyan,
                                .mint
                            ],
                            startPoint:
                            .leading,
                            endPoint:
                            .trailing
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                            18
                        )
                    )
                }
                .buttonStyle(
                    .plain
                )
            }

            EventsCalendarCard(
                events:
                viewModel.events
            )

            if viewModel.isLoading {
                loadingCard
            }

            if let errorMessage =
            viewModel.errorMessage {

                eventsUnavailableCard(
                    message:
                    errorMessage
                )
            }

            eventsSections
        }
    }

    // MARK: - HOA Board Content

    private var hoaBoardEventsContent:
    some View {

        VStack(
            alignment: .leading,
            spacing: 22
        ) {

            hoaBoardHeader
            Button {

                switchToResidentView()

            } label: {

                HStack(
                    spacing: 12
                ) {

                    Image(
                        systemName:
                        "person.fill"
                    )

                    VStack(
                        alignment:
                        .leading,
                        spacing: 3
                    ) {

                        Text(
                            "View as Resident"
                        )
                        .font(
                            .headline.bold()
                        )

                        Text(
                            "See what \(effectiveNeighborhoodName) residents see"
                        )
                        .font(
                            .caption
                        )
                        .opacity(
                            0.78
                        )
                    }

                    Spacer()

                    Image(
                        systemName:
                        "arrow.right"
                    )
                }
                .foregroundStyle(
                    .white
                )
                .padding()
                .frame(
                    maxWidth:
                    .infinity
                )
                .background(
                    LinearGradient(
                        colors: [
                            .purple,
                            .cyan
                        ],
                        startPoint:
                        .leading,
                        endPoint:
                        .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                        18
                    )
                )
            }
            .buttonStyle(
                .plain
            )
            hoaBoardCommunicationCard

            Button {

                showingCreateEvent =
                true

            } label: {

                Label(
                    "Create New Event",
                    systemImage:
                    "calendar.badge.plus"
                )
                .font(
                    .headline.bold()
                )
                .frame(
                    maxWidth:
                    .infinity
                )
                .padding()
                .foregroundStyle(
                    .black
                )
                .background(
                    LinearGradient(
                        colors: [
                            .cyan,
                            .mint
                        ],
                        startPoint:
                        .leading,
                        endPoint:
                        .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .shadow(
                    color:
                    .cyan.opacity(
                        0.35
                    ),
                    radius: 10
                )
            }
            .buttonStyle(
                .plain
            )

            EventsCalendarCard(
                events:
                viewModel.events
            )

            if viewModel.isLoading {
                loadingCard
            }

            if let errorMessage =
            viewModel.errorMessage {

                eventsUnavailableCard(
                    message:
                    errorMessage
                )
            }

            eventsSections
        }
    }

    private var hoaBoardHeader:
    some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(
                alignment: .top
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        "HOA Events"
                    )
                    .font(
                        .largeTitle.bold()
                    )
                    .foregroundStyle(
                        .white
                    )

                    Label(
                        effectiveNeighborhoodName,
                        systemImage:
                        "house.and.flag.fill"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        .cyan
                    )
                }

                Spacer()

                Text(
                    "BOARD"
                )
                .font(
                    .caption.bold()
                )
                .tracking(1)
                .foregroundStyle(
                    .black
                )
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .vertical,
                    7
                )
                .background(
                    .yellow
                )
                .clipShape(
                    Capsule()
                )
            }

            Text(
                "Create events for your neighborhood and keep residents informed."
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .white.opacity(
                    0.68
                )
            )
        }
    }

    private var hoaBoardCommunicationCard:
    some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Label(
                "Neighborhood Announcements",
                systemImage:
                "bell.badge.fill"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                .white
            )

            Text(
                """
                Publishing an event adds it to your neighborhood calendar and sends a push notification to registered residents in your community.
                """
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .white.opacity(
                    0.76
                )
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Text(
                "You can include a photo, description, date, time, and location."
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                .cyan
            )
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(
                        0.13
                    ),
                    .purple.opacity(
                        0.24
                    )
                ],
                startPoint:
                .topLeading,
                endPoint:
                .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                .cyan.opacity(
                    0.55
                ),
                lineWidth: 1
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
    }

    // MARK: - Shared Event Content

    private var roleLoadingCard:
    some View {

        HStack(
            spacing: 12
        ) {

            ProgressView()
            .tint(
                .cyan
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "Loading your event access..."
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    .white
                )

                Text(
                    "Checking your neighborhood permissions."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.65
                    )
                )
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .white.opacity(
                0.07
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var loadingCard:
    some View {

        HStack(
            spacing: 12
        ) {

            ProgressView()
            .tint(
                .cyan
            )

            Text(
                "Loading events for your area..."
            )
            .font(
                .subheadline
                .weight(
                    .semibold
                )
            )
            .foregroundStyle(
                .white.opacity(
                    0.8
                )
            )
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .white.opacity(
                0.07
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private func eventsUnavailableCard(
    message: String
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            Image(
                systemName:
                "arrow.triangle.2.circlepath"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                .orange
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "Upcoming events are being updated"
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    .white
                )

                Text(
                    message
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.65
                    )
                )
            }

            Spacer()

            Button {

                Task {

                    await viewModel.loadEvents(
                        residentId:
                        residentId,
                        isHoaBoardMember:
                        isHoaBoardViewActive
                    )
                }

            } label: {

                Image(
                    systemName:
                    "arrow.clockwise"
                )
                .foregroundStyle(
                    .cyan
                )
            }
            .buttonStyle(
                .plain
            )
        }
        .padding()
        .background(
            .white.opacity(
                0.06
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var eventsSections:
    some View {

        VStack(
            alignment: .leading,
            spacing: 28
        ) {

            EventSection(
                title:
                "Current & Upcoming Events",
                icon:
                "calendar.badge.clock",
                events:
                viewModel
                .currentAndUpcomingEvents,
                emptyMessage:
                "There are no upcoming events scheduled for your area yet."
            )

            EventSection(
                title:
                "Past Events",
                icon:
                "clock.arrow.circlepath",
                events:
                viewModel.pastEvents,
                emptyMessage:
                "Past community events will appear here."
            )
        }
    }

    // MARK: - Real Board Permission Lookup
    @MainActor
    private func switchToResidentView() {

        hoaResidentPreviewMode =
        true

        Task {

            await viewModel.loadEvents(
                residentId:
                residentId,
                isHoaBoardMember:
                false
            )
        }
    }


    @MainActor
    private func switchToBoardView() {

        hoaResidentPreviewMode =
        false

        Task {

            await viewModel.loadEvents(
                residentId:
                residentId,
                isHoaBoardMember:
                true
            )
        }
    }
    @MainActor
    private func refreshEventRole()
    async {

        guard residentId > 0 else {

            residentBoardOfDirectors =
            false

            hasResolvedEventRole =
            true

            return
        }

        guard !isResolvingEventRole
        else {
            return
        }

        isResolvingEventRole =
        true

        defer {

            isResolvingEventRole =
            false

            hasResolvedEventRole =
            true
        }

        guard let url = URL(
            string:
            "https://crm-function-app-5d4de511071d.herokuapp.com/server/resident_function/api/residents/profile/\(residentId)"
        ) else {
            return
        }

        do {

            var request =
            URLRequest(
                url: url
            )

            request.httpMethod =
            "GET"

            request.timeoutInterval =
            30

            request.setValue(
                "application/json",
                forHTTPHeaderField:
                "Accept"
            )

            let (data, response) =
            try await URLSession
            .shared
            .data(
                for:
                request
            )

            guard let httpResponse =
            response
            as? HTTPURLResponse,
            (200...299)
            .contains(
                httpResponse
                .statusCode
            )
            else {
                return
            }

            let resident =
            try JSONDecoder()
            .decode(
                ResidentEventRole.self,
                from:
                data
            )

            residentBoardOfDirectors =
            resident
            .board_of_directors ??
            false

            if let neighborhoodId =
            resident
            .neighborhood_id {

                residentNeighborhoodId =
                neighborhoodId
            }

            if let neighborhoodName =
            resident
            .neighborhood_name,
            !neighborhoodName
            .isEmpty {

                residentNeighborhoodName =
                neighborhoodName
            }

            if let areaName =
            resident
            .display_area_name,
            !areaName.isEmpty {

                displayAreaName =
                areaName
            }

            print(
                "[Events Role]",
                "resident:",
                resident.id,
                "board:",
                residentBoardOfDirectors,
                "neighborhood:",
                residentNeighborhoodName
            )

        } catch {

            /*
             * If role lookup temporarily fails,
             * keep the last cached board value.
             */
            print(
                "[Events Role] Failed:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Create HOA Event

private struct CreateNeighborhoodEventView:
View {

    @Environment(\.dismiss)
    private var dismiss

    let residentId: Int
    let neighborhoodName: String
    let onPublished: () -> Void

    @State
    private var title = ""

    @State
    private var eventDescription = ""

    @State
    private var address = ""

    @State
    private var eventDate =
    Date()
    .addingTimeInterval(
        24 * 60 * 60
    )

    @State
    private var startTime = Date()

    @State
    private var endTime =
    Date()
    .addingTimeInterval(
        2 * 60 * 60
    )

    @State
    private var selectedPhotoItem:
    PhotosPickerItem?

    @State
    private var selectedEventImage:
    UIImage?

    @State
    private var isLoadingPhoto = false

    @State
    private var isPublishing = false

    @State
    private var errorMessage = ""

    private let service =
    NeighborhoodEventsService()

    private var cleanTitle: String {
        title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanDescription:
    String {

        eventDescription
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanAddress: String {
        address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var canPublish: Bool {

        !cleanTitle.isEmpty &&
        !cleanDescription.isEmpty &&
        !isPublishing &&
        !isLoadingPhoto
    }

    var body: some View {

        NavigationStack {

            NeonBackground {

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 22
                    ) {

                        neighborhoodCard

                        eventPhotoSection

                        eventTextFields

                        eventDateAndTimeFields

                        if !errorMessage
                        .isEmpty {

                            Text(
                                errorMessage
                            )
                            .font(
                                .subheadline
                                .weight(
                                    .semibold
                                )
                            )
                            .foregroundStyle(
                                .red
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                        }

                        publishButton

                        Spacer(
                            minLength: 70
                        )
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(
                    .interactively
                )
            }
            .navigationTitle(
                "Create Event"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                    .topBarLeading
                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()
                    }
                    .foregroundStyle(
                        .cyan
                    )
                }
            }
        }
        .onChange(
            of:
            selectedPhotoItem
        ) { newItem in

            guard let newItem
            else {

                selectedEventImage =
                nil

                return
            }

            loadPhoto(
                from:
                newItem
            )
        }
    }

    private var neighborhoodCard:
    some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                neighborhoodName,
                systemImage:
                "house.and.flag.fill"
            )
            .font(
                .headline.bold()
            )
            .foregroundStyle(
                .cyan
            )

            Text(
                "This event will be published to your neighborhood."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .white.opacity(
                    0.68
                )
            )
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .white.opacity(
                0.07
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var eventPhotoSection:
    some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Event Photo"
            )
            .font(
                .headline
            )
            .foregroundStyle(
                .white
            )

            if let selectedEventImage {

                Image(
                    uiImage:
                    selectedEventImage
                )
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth:
                    .infinity
                )
                .frame(
                    height: 220
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20
                    )
                )
            }

            PhotosPicker(
                selection:
                $selectedPhotoItem,
                matching:
                .images
            ) {

                HStack {

                    if isLoadingPhoto {

                        ProgressView()
                        .tint(
                            .cyan
                        )

                    } else {

                        Image(
                            systemName:
                            selectedEventImage ==
                            nil
                            ? "photo.badge.plus"
                            : "photo.fill"
                        )
                    }

                    Text(
                        selectedEventImage ==
                        nil
                        ? "Add Event Photo"
                        : "Change Event Photo"
                    )

                    Spacer()
                }
                .font(
                    .headline
                )
                .foregroundStyle(
                    .white
                )
                .padding()
                .background(
                    .white.opacity(
                        0.08
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                    .stroke(
                        .cyan.opacity(
                            0.55
                        ),
                        lineWidth: 1
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .disabled(
                isLoadingPhoto
            )
        }
    }

    private var eventTextFields:
    some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            eventFieldLabel(
                "Event Name"
            )

            TextField(
                "Crowley Park Community Social",
                text:
                $title
            )
            .eventInputStyle()

            eventFieldLabel(
                "Description"
            )

            TextEditor(
                text:
                $eventDescription
            )
            .scrollContentBackground(
                .hidden
            )
            .foregroundStyle(
                .white
            )
            .frame(
                minHeight: 130
            )
            .padding(10)
            .background(
                .white.opacity(
                    0.08
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    .cyan.opacity(
                        0.45
                    ),
                    lineWidth: 1
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )

            eventFieldLabel(
                "Location / Address"
            )

            TextField(
                "Park, clubhouse, meeting room, or address",
                text:
                $address,
                axis:
                .vertical
            )
            .lineLimit(
                1...3
            )
            .eventInputStyle()
        }
    }

    private var eventDateAndTimeFields:
    some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            eventFieldLabel(
                "Event Date"
            )

            DatePicker(
                "Date",
                selection:
                $eventDate,
                displayedComponents:
                .date
            )
            .datePickerStyle(
                .compact
            )
            .tint(
                .cyan
            )
            .foregroundStyle(
                .white
            )

            eventFieldLabel(
                "Start Time"
            )

            DatePicker(
                "Start",
                selection:
                $startTime,
                displayedComponents:
                .hourAndMinute
            )
            .datePickerStyle(
                .compact
            )
            .tint(
                .cyan
            )
            .foregroundStyle(
                .white
            )

            eventFieldLabel(
                "End Time"
            )

            DatePicker(
                "End",
                selection:
                $endTime,
                displayedComponents:
                .hourAndMinute
            )
            .datePickerStyle(
                .compact
            )
            .tint(
                .cyan
            )
            .foregroundStyle(
                .white
            )
        }
        .padding(16)
        .background(
            .white.opacity(
                0.06
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var publishButton:
    some View {

        Button {

            Task {

                await publishEvent()
            }

        } label: {

            HStack {

                if isPublishing {

                    ProgressView()
                    .tint(
                        .black
                    )
                }

                Label(
                    isPublishing
                    ? "Publishing..."
                    : "Publish Event",
                    systemImage:
                    "bell.badge.fill"
                )
            }
            .font(
                .headline.bold()
            )
            .frame(
                maxWidth:
                .infinity
            )
            .padding()
            .foregroundStyle(
                .black
            )
            .background(
                LinearGradient(
                    colors: [
                        .yellow,
                        .orange
                    ],
                    startPoint:
                    .leading,
                    endPoint:
                    .trailing
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
        }
        .buttonStyle(
            .plain
        )
        .disabled(
            !canPublish
        )
        .opacity(
            canPublish
            ? 1
            : 0.55
        )
    }

    private func eventFieldLabel(
    _ text: String
    ) -> some View {

        Text(
            text.uppercased()
        )
        .font(
            .caption.bold()
        )
        .tracking(
            0.7
        )
        .foregroundStyle(
            .cyan
        )
    }

    private func loadPhoto(
    from item:
    PhotosPickerItem
    ) {

        isLoadingPhoto =
        true

        errorMessage =
        ""

        Task {

            do {

                guard let data =
                try await item
                .loadTransferable(
                    type:
                    Data.self
                ),
                let image =
                UIImage(
                    data:
                    data
                )
                else {

                    await MainActor.run {

                        isLoadingPhoto =
                        false

                        errorMessage =
                        "That photo could not be loaded."
                    }

                    return
                }

                await MainActor.run {

                    selectedEventImage =
                    image

                    isLoadingPhoto =
                    false
                }

            } catch {

                await MainActor.run {

                    isLoadingPhoto =
                    false

                    errorMessage =
                    error
                    .localizedDescription
                }
            }
        }
    }

    @MainActor
    private func publishEvent()
    async {

        errorMessage =
        ""

        guard canPublish
        else {
            return
        }

        guard let startsAt =
        combinedDate(
            date:
            eventDate,
            time:
            startTime
        ),
        let endsAt =
        combinedDate(
            date:
            eventDate,
            time:
            endTime
        )
        else {

            errorMessage =
            "The event date or time could not be created."

            return
        }

        guard endsAt > startsAt
        else {

            errorMessage =
            "The end time must be after the start time."

            return
        }

        var imageBase64:
        String?

        if let selectedEventImage {

            guard let uploadImage =
            selectedEventImage
            .resizedForEventUpload(
                maxDimension:
                1600
            ),
            let imageData =
            uploadImage
            .jpegData(
                compressionQuality:
                0.74
            )
            else {

                errorMessage =
                "The event photo could not be prepared for upload."

                return
            }

            imageBase64 =
            imageData
            .base64EncodedString()
        }

        isPublishing =
        true

        defer {

            isPublishing =
            false
        }

        do {

            _ = try await service
            .createEvent(
                residentId:
                residentId,
                title:
                cleanTitle,
                description:
                cleanDescription,
                address:
                cleanAddress,
                startsAt:
                startsAt,
                endsAt:
                endsAt,
                imageBase64:
                imageBase64
            )

            onPublished()

        } catch {

            errorMessage =
            error.localizedDescription
        }
    }

    private func combinedDate(
    date: Date,
    time: Date
    ) -> Date? {

        let calendar =
        Calendar.current

        let timeComponents =
        calendar
        .dateComponents(
            [
                .hour,
                .minute
            ],
            from:
            time
        )

        return calendar.date(
            bySettingHour:
            timeComponents.hour ?? 0,
            minute:
            timeComponents.minute ?? 0,
            second:
            0,
            of:
            date
        )
    }
}


// MARK: - Resident Events Intro

private struct ResidentEventsIntroCard:
View {

    private let imageURL =
    URL(
        string:
        "https://res.cloudinary.com/drna15e8q/image/upload/v1786591993/vendorevents_ypasxe.jpg"
    )

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            AsyncImage(
                url:
                imageURL
            ) { phase in

                switch phase {

                case .empty:

                    ZStack {

                        Rectangle()
                        .fill(
                            .black.opacity(
                                0.25
                            )
                        )

                        ProgressView()
                        .tint(
                            .cyan
                        )
                    }

                case .success(
                let image
                ):

                    image
                    .resizable()
                    .scaledToFill()

                case .failure:

                    ZStack {

                        LinearGradient(
                            colors: [
                                .cyan.opacity(
                                    0.25
                                ),
                                .purple.opacity(
                                    0.35
                                )
                            ],
                            startPoint:
                            .topLeading,
                            endPoint:
                            .bottomTrailing
                        )

                        Image(
                            systemName:
                            "calendar.badge.clock"
                        )
                        .font(
                            .system(
                                size: 50
                            )
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }

                @unknown default:

                    EmptyView()
                }
            }
            .frame(
                maxWidth:
                .infinity
            )
            .frame(
                height: 230
            )
            .clipped()

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Label(
                    "Community Events",
                    systemImage:
                    "person.3.fill"
                )
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    .white
                )

                Text(
                    """
                    Stay up to date with neighborhood meetings, socials, service events, and other activities posted for your community.
                    """
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.78
                    )
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text(
                    "Event dates are highlighted on the calendar below."
                )
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    .cyan
                )
            }
            .padding(18)
        }
        .frame(
            maxWidth:
            .infinity
        )
        .background(
            LinearGradient(
                colors: [
                    .cyan.opacity(
                        0.13
                    ),
                    .purple.opacity(
                        0.24
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
                cornerRadius: 24
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .cyan,
                        .purple
                    ],
                    startPoint:
                    .topLeading,
                    endPoint:
                    .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
    }
}


// MARK: - Signed-Out Promotional Content

private struct SignedOutEventsPromotion:
View {

    private let gold =
    Color(
        red: 1.0,
        green: 0.76,
        blue: 0.18
    )

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Image(
                "foodtruck"
            )
            .resizable()
            .scaledToFill()
            .frame(
                maxWidth:
                .infinity
            )
            .frame(
                height: 250
            )
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(
                            0.30
                        )
                    ],
                    startPoint:
                    .top,
                    endPoint:
                    .bottom
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 22
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            .cyan,
                            .purple
                        ],
                        startPoint:
                        .topLeading,
                        endPoint:
                        .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            )

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Text(
                    "Meet the Community"
                )
                .font(
                    .title2.bold()
                )
                .foregroundStyle(
                    .white
                )

                Text(
                    """
                    Community events bring residents, local businesses, and neighborhood leaders together.
                    """
                )
                .font(
                    .body
                )
                .foregroundStyle(
                    .white.opacity(
                        0.78
                    )
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text(
                    """
                    Create an account with your community invite code to see events scheduled for your neighborhood.
                    """
                )
                .font(
                    .body.bold()
                )
                .foregroundStyle(
                    gold
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
            .padding()
            .frame(
                maxWidth:
                .infinity,
                alignment:
                .leading
            )
            .background(
                .white.opacity(
                    0.07
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }
}
private struct CalendarDayEventsSheet:
View {

    @Environment(\.dismiss)
    private var dismiss

    let events:
    [NeighborhoodEvent]

    var body: some View {

        NavigationStack {

            NeonBackground {

                ScrollView {

                    VStack(
                        alignment:
                        .leading,
                        spacing:
                        18
                    ) {

                        ForEach(
                            events,
                            id:
                            \.uniqueId
                        ) {
                            event in

                            NeighborhoodEventCard(
                                event:
                                event
                            )
                        }
                    }
                    .padding()
                    .padding(
                        .bottom,
                        40
                    )
                }
            }
            .navigationTitle(
                events.count == 1
                ? "Event Details"
                : "Events"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                    .topBarTrailing
                ) {

                    Button(
                        "Done"
                    ) {

                        dismiss()
                    }
                    .foregroundStyle(
                        .cyan
                    )
                }
            }
        }
    }
}

// MARK: - Calendar

private struct EventsCalendarCard:
View {

    let events:
    [NeighborhoodEvent]

    @State
    private var displayedMonth =
    Date()

    @State
    private var selectedCalendarEvents:
    [NeighborhoodEvent] = []

    @State
    private var showingCalendarEvents =
    false

    private let calendar =
    Calendar.current

    private var monthTitle:
    String {

        displayedMonth
        .formatted(
            .dateTime
            .month(
                .wide
            )
            .year()
        )
    }

    private var weekdaySymbols:
    [String] {

        let symbols =
        calendar
        .veryShortWeekdaySymbols

        let first =
        calendar.firstWeekday - 1

        return Array(
            symbols[first...] +
            symbols[..<first]
        )
    }

    private var days:
    [Date?] {

        guard let monthInterval =
        calendar
        .dateInterval(
            of:
            .month,
            for:
            displayedMonth
        ),
        let firstWeek =
        calendar
        .dateInterval(
            of:
            .weekOfMonth,
            for:
            monthInterval
            .start
        )
        else {
            return []
        }

        var result:
        [Date?] = []

        let daysBeforeMonth =
        calendar
        .dateComponents(
            [
                .day
            ],
            from:
            firstWeek.start,
            to:
            monthInterval.start
        )
        .day ?? 0

        for _ in
        0..<max(
            0,
            daysBeforeMonth
        ) {

            result.append(
                nil
            )
        }

        let range =
        calendar
        .range(
            of:
            .day,
            in:
            .month,
            for:
            displayedMonth
        ) ??
        1..<2

        for dayNumber in
        range {

            if let date =
            calendar
            .date(
                bySetting:
                .day,
                value:
                dayNumber,
                of:
                displayedMonth
            ) {

                result.append(
                    date
                )
            }
        }

        while result.count % 7
        != 0 {

            result.append(
                nil
            )
        }

        return result
    }

    private func events(
    on date: Date
    ) -> [NeighborhoodEvent] {

        let dayStart =
        calendar
        .startOfDay(
            for:
            date
        )

        guard let dayEnd =
        calendar.date(
            byAdding:
            .day,
            value:
            1,
            to:
            dayStart
        )
        else {
            return []
        }


        return events.filter {
            event in

            if let endsAt =
            event.endsAt {

                /*
                 * Treat endsAt as an exclusive boundary.
                 *
                 * Example:
                 * Glen Eagles ends Oct 1 at midnight,
                 * so Sept 30 is included but Oct 1
                 * is NOT highlighted.
                 */
                return
                event.startsAt <
                dayEnd &&

                endsAt >
                dayStart

            } else {

                return
                event.startsAt >=
                dayStart &&

                event.startsAt <
                dayEnd
            }
        }
    }


    private func hasEvent(
    on date: Date
    ) -> Bool {

        !events(
            on:
            date
        ).isEmpty
    }

    private func isToday(
    _ date: Date
    ) -> Bool {

        calendar
        .isDateInToday(
            date
        )
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
                ).font(
                    .title3.bold()
                ).foregroundStyle(
                    .white
                )

                Spacer()

                Button {

                    moveMonth(
                        -1
                    )

                } label: {

                    Image(
                        systemName: "chevron.left"
                    )
                }

                Text(
                    monthTitle
                ).font(
                    .headline.bold()
                ).foregroundStyle(
                    .cyan
                ).frame(
                    minWidth: 145
                )

                Button {

                    moveMonth(
                        1
                    )

                } label: {

                    Image(
                        systemName: "chevron.right"
                    )
                }
            }.foregroundStyle(
                .cyan
            )

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(
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
                ) {
                    _,
                    symbol in

                    Text(
                        symbol
                    ).font(
                        .caption.bold()
                    ).foregroundStyle(
                        .white.opacity(
                            0.55
                        )
                    ).frame(
                        maxWidth: .infinity
                    )
                }

                ForEach(
                    Array(
                        days.enumerated()
                    ),
                    id: \.offset
                ) {
                    _,
                    date in

                    if let date {

                        let dayEvents = events(
                            on: date
                        )

                        let eventDay = !dayEvents.isEmpty

                        let today = isToday(
                            date
                        )


                        Button {

                            guard eventDay else {
                                return
                            }

                            selectedCalendarEvents = dayEvents

                            showingCalendarEvents = true

                        } label: {

                            ZStack {

                                if eventDay {

                                    Circle().fill(
                                        LinearGradient(
                                            colors: [
                                                .yellow,
                                                .orange
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ).shadow(
                                        color: .yellow.opacity(
                                            0.45
                                        ),
                                        radius: 6
                                    )

                                } else if today {

                                    Circle().stroke(
                                        .cyan,
                                        lineWidth: 2
                                    )
                                }


                                Text(
                                    "\(calendar.component(.day, from: date))"
                                ).font(
                                    .subheadline.bold()
                                ).foregroundStyle(
                                    eventDay ? .black: .white
                                )
                            }.frame(
                                height: 42
                            )
                        }.buttonStyle(
                            .plain
                        )

                    } else {

                        Color.clear.frame(
                            height: 42
                        )
                    }
                }
            }

            HStack(
                spacing: 8
            ) {

                Circle().fill(
                    .yellow
                ).frame(
                    width: 10,
                    height: 10
                )

                Text(
                    "Scheduled event"
                ).font(
                    .caption.bold()
                ).foregroundStyle(
                    .white.opacity(
                        0.72
                    )
                )
            }
        }.padding(18).frame(
            maxWidth: .infinity
        ).background(
            LinearGradient(
                colors: [
                    .cyan.opacity(
                        0.13
                    ),
                    .purple.opacity(
                        0.24
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ).clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        ).overlay(
            RoundedRectangle(
                cornerRadius: 24
            ).stroke(
                .cyan.opacity(
                    0.55
                ),
                lineWidth: 1
            )
        ).sheet(
            isPresented: $showingCalendarEvents
        ) {

            CalendarDayEventsSheet(
                events: selectedCalendarEvents
            ).presentationDetents([
                .medium,
                .large
            ])
        }
    }

    private func moveMonth(
    _ amount: Int
    ) {

        guard let newMonth =
        calendar
        .date(
            byAdding:
            .month,
            value:
            amount,
            to:
            displayedMonth
        )
        else {
            return
        }

        withAnimation(
            .easeInOut
        ) {

            displayedMonth =
            newMonth
        }
    }
}


// MARK: - Event Sections

private struct EventSection:
View {

    let title: String
    let icon: String
    let events:
    [NeighborhoodEvent]
    let emptyMessage:
    String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Label(
                title,
                systemImage:
                icon
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                .white
            )

            if events.isEmpty {

                Text(
                    emptyMessage
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.6
                    )
                )
                .padding()
                .frame(
                    maxWidth:
                    .infinity,
                    alignment:
                    .leading
                )
                .background(
                    .white.opacity(
                        0.06
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )

            } else {

                ForEach(
                    events,
                    id:
                    \.uniqueId
                ) {
                    event in

                    NeighborhoodEventCard(
                        event:
                        event
                    )
                }
            }
        }
    }
}


// MARK: - Event Card

private struct NeighborhoodEventCard:
View {

    let event:
    NeighborhoodEvent

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            if let imageURL =
            event.imageURL,
            let url =
            URL(
                string:
                imageURL
            ) {

                AsyncImage(
                    url:
                    url
                ) {
                    phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            Rectangle()
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

                    case .success(
                    let image
                    ):

                        image
                        .resizable()
                        .scaledToFill()

                    case .failure:

                        ZStack {

                            LinearGradient(
                                colors: [
                                    .cyan.opacity(
                                        0.18
                                    ),
                                    .purple.opacity(
                                        0.24
                                    )
                                ],
                                startPoint:
                                .topLeading,
                                endPoint:
                                .bottomTrailing
                            )

                            Image(
                                systemName:
                                "photo"
                            )
                            .font(
                                .largeTitle
                            )
                            .foregroundStyle(
                                .cyan
                            )
                        }

                    @unknown default:

                        EmptyView()
                    }
                }
                .frame(
                    maxWidth:
                    .infinity
                )
                .frame(
                    height: 190
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 15
                    )
                )
            }

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        event.title
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        .white
                    )

                    if let signupLabel =
                    event.signupLabel,
                    !signupLabel
                    .isEmpty {

                        Text(
                            signupLabel
                            .uppercased()
                        )
                        .font(
                            .caption.bold()
                        )
                        .foregroundStyle(
                            .cyan
                        )
                        .tracking(
                            0.5
                        )
                    }
                }

                Spacer()

                EventStatusBadge(
                    event:
                    event
                )
            }

            Divider()
            .overlay(
                .white.opacity(
                    0.15
                )
            )

            if let neighborhood =
            event
            .neighborhoodLine {

                EventDetailRow(
                    icon:
                    "mappin.and.ellipse",
                    label:
                    "Neighborhood",
                    value:
                    neighborhood
                )
            }

            if let address =
            event.address,
            !address.isEmpty {

                EventDetailRow(
                    icon:
                    "house",
                    label:
                    "Location",
                    value:
                    address
                )
            }

            EventDetailRow(
                icon:
                "calendar",
                label:
                "Date",
                value:
                event.formattedDate
            )

            EventDetailRow(
                icon:
                "clock",
                label:
                "Time",
                value:
                event.formattedTime
            )

            if let description =
            event
            .eventDescription,
            !description
            .isEmpty {

                Text(
                    description
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.72
                    )
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .padding(
                    .top,
                    2
                )
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .white.opacity(
                event.isPast
                ? 0.05
                : 0.08
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                LinearGradient(
                    colors:
                    event.isPast
                    ? [
                        .white.opacity(
                            0.25
                        ),
                        .purple.opacity(
                            0.45
                        )
                    ]
                    : [
                        .cyan,
                        .purple
                    ],
                    startPoint:
                    .topLeading,
                    endPoint:
                    .bottomTrailing
                ),
                lineWidth: 1.5
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .opacity(
            event.isPast
            ? 0.82
            : 1
        )
    }
}


private struct EventStatusBadge:
View {

    let event:
    NeighborhoodEvent

    var body: some View {

        Text(
            event.statusText
        )
        .font(
            .caption2.bold()
        )
        .foregroundStyle(
            event
            .statusForeground
        )
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            6
        )
        .background(
            event
            .statusBackground
        )
        .clipShape(
            Capsule()
        )
        .overlay(
            Capsule()
            .stroke(
                event
                .statusForeground
                .opacity(
                    0.45
                ),
                lineWidth: 1
            )
        )
    }
}


// MARK: - Event Detail Row

struct EventDetailRow:
View {

    let icon: String
    let label: String
    let value: String

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName:
                icon
            )
            .foregroundStyle(
                .cyan
            )
            .frame(
                width: 18
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(
                    label.uppercased()
                )
                .font(
                    .system(
                        size: 10,
                        weight:
                        .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(
                        0.45
                    )
                )
                .tracking(
                    0.5
                )

                Text(
                    value
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .white.opacity(
                        0.85
                    )
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }
}


// MARK: - Event Model

struct NeighborhoodEvent:
Identifiable,
Decodable {

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
    let imageURL: String?
    let eventSource: String?
    var uniqueId: String {

        let source =
        eventSource ??
        "hoa_event"

        return
        "\(source)-\(id)"
    }

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
        case imageURL = "image_url"
        case eventSource = "event_source"
    }

    var isPast: Bool {

        (endsAt ??
        startsAt) <
        Date()
    }

    var isHappeningNow:
    Bool {

        let currentDate =
        Date()

        let endingDate =
        endsAt ??
        startsAt

        return startsAt <=
        currentDate &&
        endingDate >=
        currentDate
    }

    var neighborhoodLine:
    String? {

        var components:
        [String] = []

        if let neighborhoodName,
        !neighborhoodName
        .isEmpty {

            components.append(
                neighborhoodName
            )
        }

        let cityAndState =
        [
            city,
            state
        ]
        .compactMap {
            value in

            guard let value,
            !value.isEmpty
            else {
                return nil
            }

            return value
        }
        .joined(
            separator:
            ", "
        )

        if !cityAndState
        .isEmpty {

            components.append(
                cityAndState
            )
        }

        guard !components
        .isEmpty
        else {
            return nil
        }

        return components
        .joined(
            separator:
            " — "
        )
    }

    var formattedDate:
    String {

        Self.dateFormatter
        .string(
            from:
            startsAt
        )
    }

    var formattedTime:
    String {

        let start =
        Self.timeFormatter
        .string(
            from:
            startsAt
        )

        guard let endsAt
        else {
            return start
        }

        let end =
        Self.timeFormatter
        .string(
            from:
            endsAt
        )

        return
        "\(start) – \(end)"
    }

    var statusText:
    String {

        if isHappeningNow {
            return "Happening Now"
        }

        if isPast {
            return "Completed"
        }

        if let status,
        !status.isEmpty {

            return status
            .capitalized
        }

        return "Scheduled"
    }

    var statusForeground:
    Color {

        if isHappeningNow {

            return Color(
                red: 0,
                green: 1,
                blue: 0.63
            )
        }

        if isPast {

            return .white
            .opacity(
                0.65
            )
        }

        return .cyan
    }

    var statusBackground:
    Color {

        if isHappeningNow {

            return .green
            .opacity(
                0.16
            )
        }

        if isPast {

            return .white
            .opacity(
                0.08
            )
        }

        return .cyan
        .opacity(
            0.12
        )
    }

    private static let dateFormatter:
    DateFormatter = {

        let formatter =
        DateFormatter()

        formatter.dateFormat =
        "EEEE, MMMM d, yyyy"

        return formatter
    }()

    private static let timeFormatter:
    DateFormatter = {

        let formatter =
        DateFormatter()

        formatter.dateFormat =
        "h:mm a"

        return formatter
    }()
}


// MARK: - Role Model

private struct ResidentEventRole:
Decodable {

    let id: Int
    let neighborhood_id: Int?
    let neighborhood_name: String?
    let display_area_name: String?
    let board_of_directors: Bool?
}


// MARK: - View Model

@MainActor
final class EventsViewModel:
ObservableObject {

    @Published
    private(set)
    var events:
    [NeighborhoodEvent] = []

    @Published
    private(set)
    var isLoading =
    false

    @Published
    private(set)
    var errorMessage:
    String?

    private let service =
    NeighborhoodEventsService()

    var currentAndUpcomingEvents:
    [NeighborhoodEvent] {

        events
        .filter {
            !$0.isPast
        }
        .sorted {
            $0.startsAt <
            $1.startsAt
        }
    }

    var pastEvents:
    [NeighborhoodEvent] {

        events
        .filter(
            \.isPast
        )
        .sorted {
            $0.startsAt >
            $1.startsAt
        }
    }

    func loadEvents(
    residentId: Int,
    isHoaBoardMember: Bool
    ) async {

        guard residentId > 0 else {

            clear()

            return
        }

        isLoading =
        true

        errorMessage =
        nil

        defer {

            isLoading =
            false
        }

        do {

            events =
            try await service
            .fetchEvents(
                residentId:
                residentId,
                isHoaBoardMember:
                isHoaBoardViewActive
            )

        } catch {

            errorMessage =
            error
            .localizedDescription
        }
    }

    func clear() {

        events = []

        errorMessage =
        nil

        isLoading =
        false
    }
}


// MARK: - API Service

private struct NeighborhoodEventsService {

    private let baseURL =
    URL(
        string:
        "https://crm-function-app-5d4de511071d.herokuapp.com"
    )!

    func fetchEvents(
    residentId: Int,
    isHoaBoardMember: Bool
    ) async throws
    -> [NeighborhoodEvent] {

        let path: String

        if isHoaBoardMember {

            path =
            "server/resident_function/api/hoaBoardMembers/\(residentId)/events"

        } else {

            path =
            "server/resident_function/api/residents/events/\(residentId)"
        }


        let url =
        baseURL
        .appendingPathComponent(
            path
        )

        var request =
        URLRequest(
            url: url
        )

        request.httpMethod =
        "GET"

        request.timeoutInterval =
        30

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Accept"
        )

        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse =
        response as? HTTPURLResponse
        else {
            throw EventsAPIError.invalidResponse
        }

        guard (200...299).contains(
            httpResponse.statusCode
        ) else {

            throw EventsAPIError.serverMessage(
                eventErrorMessage(
                    from: data
                ) ??
                "The events request failed with status \(httpResponse.statusCode)."
            )
        }

        let decoder =
        makeEventsDecoder()

        if let envelope =
        try? decoder.decode(
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

    func createEvent(
    residentId: Int,
    title: String,
    description: String,
    address: String,
    startsAt: Date,
    endsAt: Date,
    imageBase64: String?
    ) async throws
    -> NeighborhoodEvent {

        let url =
        baseURL
        .appendingPathComponent(
            "server/resident_function/api/hoaBoardMembers/\(residentId)/events"
        )

        let formatter =
        ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        var payload:
        [String: Any] = [

            "title":
            title,

            "description":
            description,

            "address":
            address,

            "starts_at":
            formatter
            .string(
                from:
                startsAt
            ),

            "ends_at":
            formatter
            .string(
                from:
                endsAt
            ),

            /*
             * The backend is responsible for deriving
             * neighborhood_id from residentId and
             * verifying board_of_directors = TRUE.
             */
            "publish":
            true
        ]

        if let imageBase64,
        !imageBase64.isEmpty {

            payload[
                "image_base64"
            ] =
            imageBase64
        }

        var request =
        URLRequest(
            url:
            url
        )

        request.httpMethod =
        "POST"

        request.timeoutInterval =
        60

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
            "Accept"
        )

        request.httpBody =
        try JSONSerialization
        .data(
            withJSONObject:
            payload
        )

        let (data, response) =
        try await URLSession
        .shared
        .data(
            for:
            request
        )

        guard let httpResponse =
        response
        as? HTTPURLResponse
        else {

            throw EventsAPIError
            .invalidResponse
        }

        guard (200...299)
        .contains(
            httpResponse
            .statusCode
        )
        else {

            throw EventsAPIError
            .serverMessage(
                eventErrorMessage(
                    from:
                    data
                ) ??
                "The event could not be published."
            )
        }

        let decoder =
        makeEventsDecoder()

        if let envelope =
        try? decoder
        .decode(
            CreateEventResponse.self,
            from:
            data
        ),
        let event =
        envelope.event {

            return event
        }

        if let event =
        try? decoder
        .decode(
            NeighborhoodEvent.self,
            from:
            data
        ) {

            return event
        }

        throw EventsAPIError
        .serverMessage(
            "The server published the event but did not return the new event."
        )
    }
}


private struct NeighborhoodEventsEnvelope:
Decodable {

    let events:
    [NeighborhoodEvent]
}


private struct CreateEventResponse:
Decodable {

    let success: Bool?
    let event:
    NeighborhoodEvent?
    let message: String?
    let error: String?
}


private struct EventErrorEnvelope:
Decodable {

    let error: String?
    let message: String?
}


// MARK: - API Helpers

private func makeEventsDecoder()
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
            "Invalid event date: \(value)"
        )
    }

    return decoder
}


private func eventErrorMessage(
from data: Data
) -> String? {

    guard let decoded =
    try? JSONDecoder()
    .decode(
        EventErrorEnvelope.self,
        from:
        data
    )
    else {
        return nil
    }

    return decoded.error ??
    decoded.message
}


private enum EventsAPIError:
LocalizedError {

    case invalidResponse
    case serverMessage(String)

    var errorDescription:
    String? {

        switch self {

        case .invalidResponse:

            return
            "The server returned an invalid response."

        case .serverMessage(
        let message
        ):

            return message
        }
    }
}


// MARK: - Shared Input Style

private extension View {

    func eventInputStyle()
    -> some View {

        self
        .font(
            .body
        )
        .foregroundStyle(
            .white
        )
        .padding()
        .background(
            .white.opacity(
                0.08
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16
            )
            .stroke(
                .cyan.opacity(
                    0.45
                ),
                lineWidth: 1
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .textInputAutocapitalization(
            .sentences
        )
    }
}


// MARK: - Image Resize

private extension UIImage {

    func resizedForEventUpload(
    maxDimension: CGFloat
    ) -> UIImage? {

        let largestDimension =
        max(
            size.width,
            size.height
        )

        guard largestDimension >
        maxDimension
        else {
            return self
        }

        let scale =
        maxDimension /
        largestDimension

        let newSize =
        CGSize(
            width:
            size.width *
            scale,
            height:
            size.height *
            scale
        )

        let renderer =
        UIGraphicsImageRenderer(
            size:
            newSize
        )

        return renderer.image {
            _ in

            draw(
                in:
                CGRect(
                    origin:
                    .zero,
                    size:
                    newSize
                )
            )
        }
    }
}
