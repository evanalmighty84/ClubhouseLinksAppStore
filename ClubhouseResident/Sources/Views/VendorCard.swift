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
                simpleNeighborListSection
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Swipeable version")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.9))

            TabView {
                ForEach(signedUpPeople) { person in
                    VStack(spacing: 6) {
                        Text("\(cleanName(person.first_name)) used this vendor")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                        if let distance = person.distance_miles {
                            Text("\(formatDistance(distance)) miles away")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                        }

                        if let address = person.address, !address.isEmpty {
                            Text(address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                        }
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
        }
        .padding(.top, 6)
    }

    private var simpleNeighborListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("List version")
            .font(.caption.bold())
            .foregroundStyle(.cyan.opacity(0.9))

            ForEach(signedUpPeople) { person in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.cyan)
                    .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(cleanName(person.first_name))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            if let distance = person.distance_miles {
                                Text("\(formatDistance(distance)) miles away")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                            }

                            if let address = person.address, !address.isEmpty {
                                Text("• \(address)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(10)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 4)
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