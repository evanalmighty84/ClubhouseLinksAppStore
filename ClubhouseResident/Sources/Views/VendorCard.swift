import SwiftUI

struct VendorCard: View {

    let vendor: Vendor

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            AsyncImage(url: URL(string: vendor.logo_url ?? "")) { image in
                image
                .resizable()
                .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)

            Text(vendor.company_name)
            .font(.title3.bold())
            .foregroundStyle(.white)

            Text(vendor.category)
            .foregroundStyle(.cyan)

            if let description = vendor.description {
                Text(description)
                .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}