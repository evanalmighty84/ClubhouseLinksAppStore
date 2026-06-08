import SwiftUI

// MARK: - NeonCard

struct NeonCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(text)
                .foregroundStyle(.white.opacity(0.75))
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

// MARK: - NeonTextField

struct NeonTextField: View {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .foregroundStyle(.white)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.cyan.opacity(0.7), lineWidth: 1)
            )
    }
}

// MARK: - NeonBackground

struct NeonBackground<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color.black,
                Color(red: 0.03, green: 0.02, blue: 0.12),
                Color(red: 0.08, green: 0.0, blue: 0.18)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            Circle()
                .fill(.cyan.opacity(0.22))
                .blur(radius: 70)
                .offset(x: -140, y: -280)

            Circle()
                .fill(.purple.opacity(0.28))
                .blur(radius: 80)
                .offset(x: 160, y: 260)

            content()
        }
    }
}
