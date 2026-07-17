import SwiftUI

struct FlyingBirdSpriteHeroView: View {
    @State private var hasFlownIn = false
    @State private var isFloating = false

    var body: some View {
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

            AnimatedSpriteView(
                imageName: "clubhouse_bird_flying_sprite",
                columns: 4,
                rows: 4,
                frameCount: 16,
                frameDuration: 0.09
            )
            .frame(width: 250, height: 230)
            .offset(
                x: hasFlownIn ? 0 : -340,
                y: isFloating ? -8 : 8
            )
            .scaleEffect(hasFlownIn ? 1.0 : 0.55)
            .opacity(hasFlownIn ? 1 : 0)
            .shadow(color: .cyan.opacity(0.45), radius: 18)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                hasFlownIn = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
    }
}