import SwiftUI

struct RequestView: View {
    @State private var name = ""
    @State private var phone = ""
    @State private var message = ""

    var body: some View {
        NeonBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("Submit Request")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                NeonTextField("Name", text: $name)
                NeonTextField("Phone", text: $phone)
                NeonTextField("Message", text: $message)

                Button {
                    print("Submit to Heroku API later")
                } label: {
                    Text("Send Request")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.cyan, .purple],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()
            }
            .padding()
        }
    }
}
