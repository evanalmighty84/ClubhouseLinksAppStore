import SwiftUI

struct RequestView: View {
    @State private var name = ""
    @State private var phone = ""
    @State private var message = ""

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Submit Request")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    NeonTextField("Name", text: $name)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .padding()
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.cyan.opacity(0.7), lineWidth: 1)
                        )

                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.cyan.opacity(0.7), lineWidth: 1)
                        )

                    Button {
                        hideKeyboard()
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

                    Spacer(minLength: 120)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif