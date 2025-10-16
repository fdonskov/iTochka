//
//  SecondItemScreen.swift
//  iTochka
//
//  Created by Fedor Donskov on 16.10.2025.
//

import SwiftUI
import AVKit

// MARK: - SecondItemScreen
struct SecondItemScreen: View {
    let video: VideoItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerViewModel: VideoPlayerViewModel
    
    init(video: VideoItem) {
        self.video = video
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = playerViewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(video.channelName?.first ?? "?"))
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(video.channelName ?? "Unknown")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            
                            if let views = video.numbersViews {
                                Text("\(formatViews(views)) просмотров")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            // Подписка
                        } label: {
                            Text("Подписаться")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let title = video.title {
                        Text(title)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 20) {
                        ActionButton(icon: "hand.thumbsup", text: "42", action: {})
                        ActionButton(icon: "hand.thumbsdown", text: "Не нравится", action: {})
                        ActionButton(icon: "bubble.left", text: "24", action: {})
                        ActionButton(icon: "square.and.arrow.up", text: "Поделиться", action: {})
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            playerViewModel.cleanup()
        }
    }
    
    private func formatViews(_ views: Int) -> String {
        if views >= 1_000_000 {
            return String(format: "%.1fM", Double(views) / 1_000_000)
        } else if views >= 1_000 {
            return String(format: "%.1fK", Double(views) / 1_000)
        }
        return "\(views)"
    }
}

struct ActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(text)
                    .font(.system(size: 11))
            }
            .foregroundColor(.white)
        }
    }
}

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    private let video: VideoItem
    
    init(video: VideoItem) {
        self.video = video
        setupPlayer()
    }
    
    private func setupPlayer() {
        guard let hlsURL = video.hlsURL else { return }
        let playerItem = AVPlayerItem(url: hlsURL)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = false
    }
    
    func cleanup() {
        player?.pause()
        player = nil
    }
}
