import SwiftUI
import AVKit

struct StreetFairIntroView: View {

    let residentId: Int

    @State
    private var showVideo = true

    var body: some View {

        ZStack {

            StreetFairResidentView()

            if showVideo {

                StreetFairVideoOverlay {
                    withAnimation(
                        .easeInOut(duration: 0.35)
                    ) {
                        showVideo = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}


// MARK: - Video Overlay

private struct StreetFairVideoOverlay: View {

    let onContinue: () -> Void

    @State
    private var player: AVPlayer?

    @State
    private var videoEnded = false


    var body: some View {

        ZStack {

            Color.black
            .ignoresSafeArea()


            if let player {

                VideoPlayer(
                    player: player
                )
                .ignoresSafeArea()
                .onAppear {

                    player.seek(
                        to: .zero
                    )

                    player.play()
                }

            } else {

                Color.black
                .ignoresSafeArea()

                ProgressView()
                .tint(.white)
            }


            /*
             Dark overlay makes the center
             controls easy to read.
             */
            LinearGradient(
                colors: [
                    .black.opacity(0.15),
                    .black.opacity(0.05),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)


            VStack {

                Spacer()


                VStack(spacing: 14) {

                    Text(
                        "GLEN EAGLES STREET FAIR"
                    )
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.9))


                    Button {

                        continueToStreetFair()

                    } label: {

                        HStack(spacing: 10) {

                            Image(
                                systemName:
                                "arrow.right.circle.fill"
                            )

                            Text(
                                videoEnded
                                ? "Enter Street Fair"
                                : "Continue to Street Fair"
                            )
                        }
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: 300
                        )
                        .padding(
                            .vertical,
                            16
                        )
                        .background(
                            LinearGradient(
                                colors: [
                                    .orange,
                                    .purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                        .overlay {

                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                            .stroke(
                                .white.opacity(0.30),
                                lineWidth: 1
                            )
                        }
                        .shadow(
                            color:
                            .purple.opacity(0.55),
                            radius: 18
                        )
                    }
                    .buttonStyle(.plain)


                    if !videoEnded {

                        Button {

                            continueToStreetFair()

                        } label: {

                            Text("Skip Video")
                            .font(.subheadline.bold())
                            .foregroundStyle(
                                .white.opacity(0.85)
                            )
                            .padding(
                                .horizontal,
                                20
                            )
                            .padding(
                                .vertical,
                                10
                            )
                            .background(
                                .black.opacity(0.40)
                            )
                            .clipShape(
                                Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 15)
            }
        }
        .onAppear {

            configurePlayer()
        }
        .onDisappear {

            player?.pause()

            NotificationCenter.default
            .removeObserver(self)
        }
    }


    // MARK: - Configure Player

    private func configurePlayer() {

        guard player == nil else {
            return
        }

        guard let url =
        Bundle.main.url(
            forResource:
            "streetfair_intro",
            withExtension:
            "mp4"
        )
        else {

            print(
                "[Street Fair Intro] Video not found."
            )

            return
        }


        let newPlayer =
        AVPlayer(url: url)

        /*
         Set to false if you want the video's
         actual audio to play automatically.
         */
        newPlayer.isMuted = false

        player = newPlayer


        NotificationCenter.default
        .addObserver(
            forName:
            .AVPlayerItemDidPlayToEndTime,
            object:
            newPlayer.currentItem,
            queue:
            .main
        ) { _ in

            videoEnded = true
        }


        newPlayer.play()
    }


    // MARK: - Continue

    private func continueToStreetFair() {

        player?.pause()

        onContinue()
    }
}