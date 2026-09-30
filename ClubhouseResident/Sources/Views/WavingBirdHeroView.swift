import SwiftUI

struct WavingBirdHeroView: View {

    @State
    private var hasFlownIn = false

    @State
    private var isWaving = false

    @State
    private var isFloating = false

    var birdHeight: CGFloat = 230
    var glowSize: CGFloat = 250
    var containerHeight: CGFloat = 260

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
            .frame(
                width: glowSize,
                height: glowSize
            )
            .blur(radius: 10)

            Image(
                "clubhouse_bird_wave_sprite_512"
            )
            .resizable()
            .scaledToFit()
            .frame(
                height: birdHeight
            )
            .offset(
                x: hasFlownIn ? 0 : -340,
                y: isFloating ? -8 : 8
            )
            .rotationEffect(
                .degrees(
                    isWaving ? -4 : 4
                )
            )
            .scaleEffect(
                hasFlownIn
                ? 1.0
                : 0.55
            )
            .opacity(
                hasFlownIn
                ? 1
                : 0
            )
            .shadow(
                color:
                .cyan.opacity(0.45),
                radius: 18
            )
        }
        .frame(
            height: containerHeight
        )
        .frame(
            maxWidth: .infinity
        )
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {

        withAnimation(
            .spring(
                response: 0.8,
                dampingFraction: 0.72
            )
        ) {
            hasFlownIn = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.65
        ) {

            withAnimation(
                .easeInOut(
                    duration: 0.36
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {
                isWaving = true
            }

            withAnimation(
                .easeInOut(
                    duration: 1.4
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {
                isFloating = true
            }
        }
    }
}