//
//  VideoService.swift
//  iTochka
//
//  Created by Fedor Donskov on 16.10.2025.
//

import Foundation

// MARK: - VideoService
final class VideoService {
    private let baseURL = "https://interesnoitochka.ru/api/v1/videos/recommendations"
    
    func fetchVideos(offset: Int = 0, limit: Int = 10) async throws -> VideosResponse {
        var comps = URLComponents(string: baseURL)!
        comps.queryItems = [
            .init(name: "offset", value: String(offset)),
            .init(name: "limit", value: String(limit)),
            .init(name: "category", value: "shorts"),
            .init(name: "date_filter_type", value: "created"),
            .init(name: "sort_by", value: "date_created"),
            .init(name: "sort_order", value: "desc"),
        ]
        
        guard let url = comps.url else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(VideosResponse.self, from: data)
    }
}
