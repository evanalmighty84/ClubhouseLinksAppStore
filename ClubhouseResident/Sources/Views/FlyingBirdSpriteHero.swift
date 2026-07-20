import SwiftUI

struct FlyingBirdSpriteHeroView: View {
    @State private var hasFlownIn = false
    @State private var isFloating = false
    @State private var currentFrame = 0

    private let frames = (0..<7).map {
        String(format: "clubhouse_bird_flying_%02d", $0)
    }

    private let timer = Timer.publish(
        every: 0.28,
        on: .main,
        in: .common
    ).autoconnect()

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

            Image(frames[currentFrame])
            .resizable()
            .scaledToFit()
            .frame(height: 230)
            .offset(
                x: hasFlownIn ? 0 : -340,
                y: isFloating ? -8 : 8
            )
            .scaleEffect(hasFlownIn ? 1.0 : 0.55)
            .opacity(hasFlownIn ? 1 : 0)
            .shadow(color: .cyan.opacity(0.45), radius: 18)
        }
        .frame(height: 330)
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            currentFrame = (currentFrame + 1) % frames.count
        }
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