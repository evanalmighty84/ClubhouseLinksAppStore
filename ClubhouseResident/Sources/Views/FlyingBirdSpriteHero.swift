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
            .frame(width: 170, height: 170)
            .blur(radius: 10)

            AnimatedSpriteView(
                imageName: "clubhouse_bird_flying_sprite",
                columns: 4,
                rows: 4,
                frameCount: 16,
                frameDuration: 0.09
            )
            .frame(height: 145)
            .offset(
                x: hasFlownIn ? 0 : -320,
                y: isFloating ? -7 : 7
            )
            .scaleEffect(hasFlownIn ? 1.0 : 0.65)
            .opacity(hasFlownIn ? 1 : 0)
            .shadow(color: .cyan.opacity(0.45), radius: 14)
        }
        .frame(height: 155)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.72)) {
                hasFlownIn = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
    }
}