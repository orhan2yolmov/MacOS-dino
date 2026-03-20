//
//  WallpaperServiceViewModel.swift
//  MacOSDino
//
//  Created by Orhan on 20.03.2026.
//

import Foundation
import Combine

@MainActor
class WallpaperServiceViewModel: ObservableObject {
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let wallpaperService = WallpaperService.shared

    func loadWallpapers(sort: WallpaperSortOption) async {
        isLoading = true
        errorMessage = nil
        
        do {
            wallpapers = try await wallpaperService.fetchWallpapers(sortBy: sort)
        } catch {
            errorMessage = "Failed to load wallpapers: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
