import SwiftUI

struct EventsView: View {
    var body: some View {
        NeonBackground {
            VStack(alignment: .leading, spacing: 18) {
                Text("Upcoming Events")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                MeetAndGreetCard()

                NeonCard(title: "Neighborhood Vendor Meet & Greet",
                         text: "Details coming soon.")

                Spacer()
            }
            .padding()
        }
    }
}

struct MeetAndGreetCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Country Place Local Meet & Greet")
                .font(.headline)
                .foregroundStyle(.white)

            Text("COUNTRY PLACE SIGNUP SHEET")
                .font(.caption.bold())
                .foregroundStyle(.cyan)
                .tracking(0.5)

            Divider()
                .overlay(.white.opacity(0.15))

            EventDetailRow(icon: "mappin.and.ellipse", label: "Neighborhood", value: "Country Place — Plano, Texas")
            EventDetailRow(icon: "house",              label: "Address",      value: "3600 Country Place Dr, Plano, TX")
            EventDetailRow(icon: "calendar",           label: "Date",         value: "Sunday, June 14th")
            EventDetailRow(icon: "clock",              label: "Time",         value: "12:00 PM – 3:00 PM")

            Text("Going on as scheduled")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(Color(red: 0, green: 1, blue: 0.63))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 1))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(colors: [.cyan, .purple],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct EventDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(0.5)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}
