import SwiftUI

struct FlyingBirdHeroView: View {
    @State private var hasFlownIn = false
    @State private var isWaving = false
    @State private var isFloating = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .cyan.opacity(0.18),
                            .purple.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 250)
                .blur(radius: 10)

                Image("clubhouse_bird_wave_sprite_512")
                .resizable()
                .scaledToFit()
                .frame(height: 230)
                .offset(
                    x: hasFlownIn ? 0 : -340,
                    y: isFloating ? -8 : 8
                )
                .rotationEffect(.degrees(isWaving ? -4 : 4))
                .scaleEffect(hasFlownIn ? 1.0 : 0.55)
                .opacity(hasFlownIn ? 1 : 0)
                .shadow(color: .cyan.opacity(0.45), radius: 18)
            }
            .frame(height: 260)

            Text("Start Your Next Project")
            .font(.title.bold())
            .foregroundStyle(.white)

            Text("Choose a service, compare trusted local vendors, and see who your neighbors have used.")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(.horizontal, 12)

            NavigationLink {
                StartServiceView()
            } label: {
                Text("Start a Service")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .cyan.opacity(0.4), radius: 12)
            }
            .padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                hasFlownIn = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeInOut(duration: 0.36).repeatForever(autoreverses: true)) {
                    isWaving = true
                }

                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
    }
}