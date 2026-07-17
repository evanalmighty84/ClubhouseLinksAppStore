import SwiftUI
import UIKit

struct AnimatedSpriteView: View {
    let imageName: String
    let columns: Int
    let rows: Int
    let frameCount: Int
    let frameDuration: Double

    @State private var currentFrame = 0
    @State private var timer: Timer?

    var body: some View {
        Group {
            if let frameImage = currentFrameImage {
                Image(uiImage: frameImage)
                .resizable()
                .scaledToFit()
            } else {
                Color.clear
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    private var currentFrameImage: UIImage? {
        guard let spriteSheet = UIImage(named: imageName),
        let cgImage = spriteSheet.cgImage else {
            return nil
        }

        let frameWidth = cgImage.width / columns
        let frameHeight = cgImage.height / rows

        let column = currentFrame % columns
        let row = currentFrame / columns

        let cropRect = CGRect(
            x: column * frameWidth,
            y: row * frameHeight,
            width: frameWidth,
            height: frameHeight
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: croppedCGImage)
    }

    private func startAnimation() {
        stopAnimation()

        timer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            currentFrame = (currentFrame + 1) % frameCount
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}