import SwiftUI

struct VendorCard: View {

    let vendor: Vendor

    private var signupCount: Int {
        vendor.signup_count ?? 0
    }

    private var signedUpPeople: [VendorSignupPerson] {
        vendor.signed_up_people ?? []
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            AsyncImage(url: URL(string: vendor.logo_url ?? "")) { image in
                image
                .resizable()
                .scaledToFit()
            } placeholder: {
                ProgressView()
                .tint(.cyan)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)

            Text(vendor.company_name)
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text(vendor.category ?? "")
            .foregroundStyle(.cyan)

            if let description = vendor.description, !description.isEmpty {
                Text(description)
                .foregroundStyle(.white.opacity(0.75))
            }

            neighborSummary

            if !signedUpPeople.isEmpty {
                swipeableNeighborSection
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var neighborSummary: some View {
        Group {
            if signupCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                    .foregroundStyle(.cyan)

                    Text("\(signupCount) neighbor\(signupCount == 1 ? "" : "s") use this vendor")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                }
                .padding(.top, 4)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                    .foregroundStyle(.white.opacity(0.45))

                    Text("No nearby neighbors listed yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.top, 4)
            }
        }
    }

    private var swipeableNeighborSection: some View {
        TabView {
            ForEach(signedUpPeople) { person in
                HStack(alignment: .center, spacing: 14) {

                    Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.cyan)
                    .font(.system(size: 34))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(cleanName(person.first_name)) used this vendor")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)

                        if let photoUrl = person.finished_photo_url,
                        !photoUrl.isEmpty,
                        let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { image in
                                image
                                .resizable()
                                .scaledToFill()
                            } placeholder: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                    .fill(.black.opacity(0.25))

                                    ProgressView()
                                    .tint(.cyan)
                                }
                            }
                            .frame(width: 82, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.vertical, 2)
                        }

                        if let distance = person.distance_miles {
                            Text("\(formatDistance(distance)) miles away")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                        }

                        if let address = person.address, !address.isEmpty {
                            Text(address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 130)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .padding(.top, 8)
    }

    private func cleanName(_ name: String?) -> String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "A neighbor"
        }

        return trimmed
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance < 0.05 {
            return "0.0"
        }

        if distance < 1 {
            return String(format: "%.2f", distance)
        }

        return String(format: "%.1f", distance)
    }
}