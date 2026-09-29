import SwiftUI
import AVFoundation
import UIKit

final class LoopingPlayerView: UIView {

    override static var layerClass:
    AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer:
    AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

struct LoopingBirdVideoView:
UIViewRepresentable {

    let resourceName: String
    let fileExtension: String

    func makeCoordinator()
    -> Coordinator {
        Coordinator()
    }

    func makeUIView(
    context: Context
    ) -> LoopingPlayerView {

        let view =
        LoopingPlayerView()

        view.backgroundColor =
        .black

        view.playerLayer.videoGravity =
        .resizeAspectFill

        guard let url =
        Bundle.main.url(
            forResource:
            resourceName,
            withExtension:
            fileExtension
        )
        else {
            return view
        }

        let item =
        AVPlayerItem(
            url: url
        )

        let player =
        AVQueuePlayer()

        player.isMuted =
        true

        context.coordinator.player =
        player

        context.coordinator.looper =
        AVPlayerLooper(
            player: player,
            templateItem: item
        )

        view.playerLayer.player =
        player

        player.play()

        return view
    }

    func updateUIView(
    _ uiView: LoopingPlayerView,
    context: Context
    ) {

        context.coordinator.player?
        .play()
    }

    static func dismantleUIView(
    _ uiView: LoopingPlayerView,
    coordinator: Coordinator
    ) {

        coordinator.player?
        .pause()

        coordinator.looper =
        nil

        coordinator.player =
        nil
    }

    final class Coordinator {

        var player:
        AVQueuePlayer?

        var looper:
        AVPlayerLooper?
    }
}