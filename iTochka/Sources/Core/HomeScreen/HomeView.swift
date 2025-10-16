//
//  HomeView.swift
//  iTochka
//
//  Created by Fedor Donskov on 15.10.2025.
//

import SwiftUI
import UIKit
import AVFoundation
import AVKit

// MARK: - HomeView
struct HomeView: View {
    @State private var selectedVideo: VideoItem?
    @State private var feedViewController: VideoFeedViewController?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VideoFeedContainer(selectedVideo: $selectedVideo, viewController: $feedViewController)
                    .ignoresSafeArea()
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedVideo) { video in
                SecondItemScreen(video: video)
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            feedViewController?.playCenteredCell()
                        }
                    }
            }
        }
    }
}

// MARK: - VideoFeedContainer
struct VideoFeedContainer: UIViewControllerRepresentable {
    @Binding var selectedVideo: VideoItem?
    @Binding var viewController: VideoFeedViewController?

    func makeUIViewController(context: Context) -> VideoFeedViewController {
        let vc = VideoFeedViewController()
        vc.onVideoTapped = { [weak vc] video in
            guard let vc else { return }
            
            vc.stopAllPlayback()
            selectedVideo = video
        }

        DispatchQueue.main.async {
            viewController = vc
        }

        return vc
    }

    func updateUIViewController(_ vc: VideoFeedViewController, context: Context) {
        vc.onVideoTapped = { [weak vc] video in
            guard let vc else { return }
            
            vc.stopAllPlayback()
            selectedVideo = video
        }
    }
}

// MARK: - HomeViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var items: [VideoItem] = []
    @Published var total: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = VideoService()

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.fetchVideos(offset: 0, limit: 10)
            self.items = response.items
            self.total = response.total
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Не удалось загрузить ленту: \(error.localizedDescription)"
            self.items = []
            self.total = 0
        }
    }
}
