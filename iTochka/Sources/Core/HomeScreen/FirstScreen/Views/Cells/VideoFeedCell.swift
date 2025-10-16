//
//  VideoFeedCell.swift
//  iTochka
//
//  Created by Fedor Donskov on 16.10.2025.
//

import UIKit
import AVFoundation
import AVKit

// MARK: - VideoFeedCell
final class VideoFeedCell: UICollectionViewCell {
    static let reuseID = "VideoFeedCell"

    var onPhotoTimeElapsed: (() -> Void)?
    var onTap: (() -> Void)?

    private let container = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let channelLabel = UILabel()

    private(set) var player: AVPlayer?
    private let playerLayer = AVPlayerLayer()
    private var endObserver: Any?
    private var currentItem: VideoItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = container.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cleanup()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .black
        container.layer.cornerRadius = 24
        container.layer.masksToBounds = true
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        channelLabel.font = .systemFont(ofSize: 14)
        channelLabel.textColor = UIColor.white.withAlphaComponent(0.85)

        let bottomStack = UIStackView(arrangedSubviews: [titleLabel, channelLabel])
        bottomStack.axis = .vertical
        bottomStack.spacing = 6
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomStack)
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        playerLayer.videoGravity = .resizeAspectFill
        container.layer.insertSublayer(playerLayer, below: bottomStack.layer)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        container.addGestureRecognizer(tap)

        container.isUserInteractionEnabled = true
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 2.0
        container.addGestureRecognizer(longPress)
    }

    @objc private func didTap() {
        onTap?()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        VideoFeedViewController.isSoundEnabled.toggle()
        let newState = VideoFeedViewController.isSoundEnabled

        if let p = player {
            p.isMuted = !newState
            p.volume = newState ? 1.0 : 0.0
        }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }

    private func cleanup() {
        if let o = endObserver { NotificationCenter.default.removeObserver(o); endObserver = nil }
        player?.pause(); player = nil
        playerLayer.player = nil
        imageView.isHidden = false
        imageView.image = nil
        currentItem = nil
    }

    func configure(with item: VideoItem) {
        cleanup()
        currentItem = item

        titleLabel.text = item.title
        channelLabel.text = item.channelName

        if let preview = item.previewImage, let url = URL(string: preview) {
            URLSession.shared.dataTask(with: url) { [weak self] data,_,_ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.imageView.image = img }
            }.resume()
        }

        if item.isVideo, let hls = item.hlsURL {
            prepareVideo(hlsURL: hls)
        } else {

        }
    }

    /// Запуск воспроизведения с учетом глобального состояния звука
    func playWithSound() {
        guard let it = currentItem else {
            return
        }
        if it.isVideo {
            if let p = player, p.rate > 0 {
                let soundEnabled = VideoFeedViewController.isSoundEnabled
                p.isMuted = !soundEnabled
                p.volume = soundEnabled ? 1.0 : 0.0
                return
            }
            startVideoWithSound()
        } else {

        }
    }

    func stopPlayback() {
        guard player?.rate != 0 else { return }
        
        imageView.isHidden = false
        if let id = currentItem?.videoId { print("stop id=\(id)") }
    }

    // MARK: - Private
    private func prepareVideo(hlsURL: URL) {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        let soundEnabled = VideoFeedViewController.isSoundEnabled
        let item = AVPlayerItem(url: hlsURL)
        player = AVPlayer(playerItem: item)
        player?.isMuted = !soundEnabled
        player?.volume = soundEnabled ? 1.0 : 0.0
        playerLayer.player = player

        print("Player created, sound=\(soundEnabled ? "ON" : "OFF"), muted=\(player?.isMuted ?? true), volume=\(player?.volume ?? 0)")

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            let currentSoundEnabled = VideoFeedViewController.isSoundEnabled
            self.player?.isMuted = !currentSoundEnabled
            self.player?.volume = currentSoundEnabled ? 1.0 : 0.0
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }

    private func startVideoWithSound() {
        guard let p = player, let id = currentItem?.videoId else {
            if let id = currentItem?.videoId { print("no player id=\(id)") }
            return
        }

        let soundEnabled = VideoFeedViewController.isSoundEnabled
        print("play id=\(id), global sound=\(soundEnabled ? "ON" : "OFF")")

        let audioSession = AVAudioSession.sharedInstance()
        do {
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to activate audio session: \(error)")
        }

        container.layoutIfNeeded()
        playerLayer.frame = container.bounds

        p.isMuted = !soundEnabled
        p.volume = soundEnabled ? 1.0 : 0.0

        print("Sound applied: muted=\(p.isMuted), volume=\(p.volume)")

        imageView.isHidden = true

        p.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        p.play()
    }
}
