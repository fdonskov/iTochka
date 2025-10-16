//
//  VideosResponseModel.swift
//  iTochka
//
//  Created by Fedor Donskov on 16.10.2025.
//

import Foundation

// MARK: - Models
struct VideosResponse: Codable {
    let total: Int
    let offset: Int
    let limit: Int
    let count: Int
    let filter: Filter
    let items: [VideoItem]
}

struct Filter: Codable {
    let search: String?
    let videoId: Int?
    let category: String?
    let channelId: Int?
    let userId: Int?
    let isFree: Bool?
    let authRequired: Bool?
    let datePeriod: String?
    let dateFilterType: String?
    let sortBy: String?
    let sortOrder: String?
}

struct VideoItem: Identifiable, Codable, Hashable {
    let videoId: Int
    let title: String?
    let previewImage: String?
    let postImage: String?
    let channelId: Int?
    let channelName: String?
    let channelAvatar: String?
    let numbersViews: Int?
    let durationSec: Int?
    let free: Bool?
    let vertical: Bool?
    let seoUrl: String?
    let datePublication: String?
    let draft: Bool?
    let timeNotReg: Int?
    let timeNotPay: Int?
    let hasAccess: Bool?
    let contentType: String?
    let latitude: Double?
    let longitude: Double?
    let locationText: String?
    let playlistId: Int?

    var id: Int { videoId }
}

extension VideoItem {
    var isVideo: Bool { (contentType?.uppercased() == "VIDEO") }
    var hlsURL: URL? {
        guard isVideo else { return nil }
        return URL(string: "https://interesnoitochka.ru/api/v1/videos/video/\(videoId)/hls/playlist.m3u8")
    }
}
