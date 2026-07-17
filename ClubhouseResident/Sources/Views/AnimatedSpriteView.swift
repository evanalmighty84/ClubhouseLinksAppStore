import SwiftUI
import UIKit

struct AnimatedSpriteView: View {
    let imageName: String
    let columns: Int
    let rows: Int
    let frameCount: Int
    let frameDuration: Double

    @State private var frames: [UIImage] = []
    @State private var currentFrame = 0
    @State private var timer: Timer?

    var body: some View {
        Group {
            if frames.indices.contains(currentFrame) {
                Image(uiImage: frames[currentFrame])
                .resizable()
                .scaledToFit()
            } else {
                Image("clubhouse_bird_wave_sprite_512")
                .resizable()
                .scaledToFit()
            }
        }
        .onAppear {
            loadFrames()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    private func loadFrames() {
        guard frames.isEmpty else { return }

        guard let spriteSheet = UIImage(named: imageName),
        let cgImage = spriteSheet.cgImage else {
            print("Could not load sprite sheet named:", imageName)
            return
        }

        let frameWidth = cgImage.width / columns
        let frameHeight = cgImage.height / rows

        var loadedFrames: [UIImage] = []

        for index in 0..<frameCount {
            let column = index % columns
            let row = index / columns

            let cropRect = CGRect(
                x: column * frameWidth,
                y: row * frameHeight,
                width: frameWidth,
                height: frameHeight
            )

            if let cropped = cgImage.cropping(to: cropRect) {
                loadedFrames.append(
                    UIImage(
                        cgImage: cropped,
                        scale: spriteSheet.scale,
                        orientation: spriteSheet.imageOrientation
                    )
                )
            }
        }

        frames = loadedFrames
        print("Loaded sprite frames:", loadedFrames.count)
    }

    private func startAnimation() {
        stopAnimation()

        timer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            guard !frames.isEmpty else { return }
            currentFrame = (currentFrame + 1) % frames.count
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}