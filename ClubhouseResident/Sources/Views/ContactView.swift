import SwiftUI

struct ContactView: View {
    var body: some View {
        NeonBackground {
            VStack(alignment: .leading, spacing: 20) {
                Text("Contact")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                NeonCard(title: "Need Help?",
                         text: "Contact your community team or submit a resident request.")

                Link("Call Clubhouse Links", destination: URL(string: "tel:2145489175")!)
                    .font(.headline)
                    .foregroundStyle(.cyan)

                Spacer()
            }
            .padding()
        }
    }
}
