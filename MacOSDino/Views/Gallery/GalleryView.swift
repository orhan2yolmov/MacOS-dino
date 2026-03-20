// GalleryView.swift
// MacOS-Dino – Professional Gallery (Dark Theme Redesign)
// HTML Reference-based 3-column layout: Sidebar | Grid | Detail

import SwiftUI

// MARK: - Gallery Navigation Tab

enum GalleryNavTab: String, CaseIterable {
    case hot = "Popüler"
    case new = "Yeni"
    case favorites = "Favoriler"
    case uploads = "Yüklediklerim"
    case downloaded = "İndirilenler"

    var icon: String {
        switch self {
        case .hot: return "flame.fill"
        case .new: return "sparkles"
        case .favorites: return "heart.fill"
        case .uploads: return "icloud.and.arrow.up.fill"
        case .downloaded: return "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .hot: return .orange
        case .new: return DinoColors.primary
        case .favorites: return .pink
        case .uploads: return .cyan
        case .downloaded: return DinoColors.success
        }
    }
}

// MARK: - Gallery View

struct GalleryView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    @StateObject private var viewModel = WallpaperServiceViewModel()
    @ObservedObject private var localManager = WallpaperManager.shared

    @State private var selectedWallpaper: Wallpaper?
    @State private var searchText = ""
    @State private var selectedNavTab: GalleryNavTab = .hot
    @State private var selectedCategories: Set<WallpaperCategory> = []
    @State private var selectedRatios: Set<AspectRatio> = []
    @State private var viewMode: ViewMode = .grid

    enum ViewMode { case grid, list }

    var body: some View {
        HStack(spacing: 0) {
            gallerySidebar
            Rectangle().fill(DinoColors.border.opacity(0.4)).frame(width: 1)
            galleryMainContent
            Rectangle().fill(DinoColors.border.opacity(0.4)).frame(width: 1)
            galleryDetailPanel
        }
        .background(DinoColors.bg)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadWallpapers(sort: .hot)
        }
    }

    // MARK: - All Displayable Wallpapers

    private var displayableWallpapers: [Wallpaper] {
        var all = localManager.allLocalWallpapers

        // Add remote wallpapers that aren't duplicates of local ones
        let localIDs = Set(all.map { $0.id })
        for wp in viewModel.wallpapers where !localIDs.contains(wp.id) {
            all.append(wp)
        }

        // Filter by search
        if !searchText.isEmpty {
            all = all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Filter by selected categories
        if !selectedCategories.isEmpty {
            all = all.filter { selectedCategories.contains($0.category) }
        }

        // Filter by selected ratios
        if !selectedRatios.isEmpty {
            all = all.filter { selectedRatios.contains($0.aspectRatio) }
        }

        // Filter by nav tab
        switch selectedNavTab {
        case .hot:
            all.sort { $0.popularityScore > $1.popularityScore }
        case .new:
            all.sort { $0.createdAt > $1.createdAt }
        case .favorites:
            all = all.filter { $0.isFeatured }
        case .downloaded:
            all = all.filter { $0.isDownloaded }
        case .uploads:
            all = all.filter { $0.category == .personal }
        }

        return all
    }

    // MARK: - Left Sidebar (w-72 → 260pt)

    private var gallerySidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [DinoColors.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "sparkles.rectangle.stack").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wallpapers").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    Text("Professional Suite").font(.system(size: 10, weight: .medium)).foregroundStyle(DinoColors.textDim)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(DinoColors.textDim)
                TextField("Ara...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(DinoColors.border.opacity(0.5), lineWidth: 1)))
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            Divider().foregroundStyle(DinoColors.border).opacity(0.3)

            // Scrollable sidebar content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    // Navigation section
                    sidebarSectionHeader("NAVİGASYON")
                    ForEach(GalleryNavTab.allCases, id: \.self) { tab in
                        sidebarNavButton(tab: tab)
                    }

                    // Categories section
                    sidebarSectionHeader("KATEGORİLER")
                    ForEach(WallpaperCategory.allCases.prefix(8)) { category in
                        sidebarCheckbox(
                            label: category.displayName,
                            isSelected: selectedCategories.contains(category),
                            color: category.color
                        ) {
                            if selectedCategories.contains(category) { selectedCategories.remove(category) }
                            else { selectedCategories.insert(category) }
                        }
                    }

                    // Aspect Ratio section
                    sidebarSectionHeader("ORAN")
                    ForEach(AspectRatio.allCases.prefix(3)) { ratio in
                        sidebarCheckbox(
                            label: ratio.rawValue,
                            isSelected: selectedRatios.contains(ratio),
                            color: DinoColors.primary
                        ) {
                            if selectedRatios.contains(ratio) { selectedRatios.remove(ratio) }
                            else { selectedRatios.insert(ratio) }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider().foregroundStyle(DinoColors.border).opacity(0.3)

            // Refresh button at bottom
            Button {
                Task { await viewModel.loadWallpapers(sort: selectedNavTab == .new ? .new : .hot) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                    Text("Verileri Yenile").font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(DinoColors.textSec)
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 240)
        .background(Color(red: 0.039, green: 0.059, blue: 0.094))
    }

    // MARK: - Sidebar Helpers

    private func sidebarSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(DinoColors.textDim)
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func sidebarNavButton(tab: GalleryNavTab) -> some View {
        let isActive = selectedNavTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedNavTab = tab }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? tab.color : DinoColors.textSec)
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .white : DinoColors.textSec)
                Spacer()
                if isActive {
                    Circle().fill(tab.color).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(isActive ? tab.color.opacity(0.12) : Color.clear))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private func sidebarCheckbox(label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? color : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(isSelected ? color : DinoColors.border, lineWidth: 1.5))
                    .frame(width: 16, height: 16)
                    .overlay(isSelected ? Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white) : nil)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : DinoColors.textSec)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content (Grid)

    private var galleryMainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Discovery")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(displayableWallpapers.count) wallpaper bulundu")
                        .font(.system(size: 12))
                        .foregroundStyle(DinoColors.textDim)
                }

                Spacer()

                // View mode toggle
                HStack(spacing: 4) {
                    gridToggleButton(mode: .grid, icon: "square.grid.2x2.fill")
                    gridToggleButton(mode: .list, icon: "list.bullet")
                }
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.surface))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Grid
            if displayableWallpapers.isEmpty {
                Spacer()
                emptyStateView
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(displayableWallpapers) { wallpaper in
                            WallpaperCard(
                                wallpaper: wallpaper,
                                isSelected: selectedWallpaper?.id == wallpaper.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedWallpaper = wallpaper }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(minWidth: 460)
        .background(DinoColors.bg)
    }

    private func gridToggleButton(mode: ViewMode, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(viewMode == mode ? .white : DinoColors.textDim)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(viewMode == mode ? DinoColors.primary.opacity(0.6) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(DinoColors.textDim)
            Text("Wallpaper Bulunamadı")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(DinoColors.textSec)
            Text("Farklı filtreler deneyin veya arama yapın")
                .font(.system(size: 12)).foregroundStyle(DinoColors.textDim)
        }
    }

    // MARK: - Detail Panel (right sidebar w-80 → 300pt)

    private var galleryDetailPanel: some View {
        Group {
            if let wallpaper = selectedWallpaper {
                WallpaperDetailView(wallpaper: wallpaper)
                    .environmentObject(engine)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(DinoColors.textDim.opacity(0.5))
                    Text("Wallpaper Seçin")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DinoColors.textSec)
                    Text("Detayları ve önizlemeyi\nburada görüntüleyin")
                        .font(.system(size: 11))
                        .foregroundStyle(DinoColors.textDim)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
        .frame(width: 300)
        .background(Color(red: 0.047, green: 0.067, blue: 0.106))
    }
}

// MARK: - WallpaperService ViewModel

@MainActor
final class WallpaperServiceViewModel: ObservableObject {
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = WallpaperService.shared
    private var currentPage = 0

    func loadWallpapers(
        category: WallpaperCategory? = nil,
        sort: WallpaperSortOption = .hot,
        page: Int = 0
    ) async {
        isLoading = true
        currentPage = page

        do {
            let results = try await service.fetchWallpapers(page: page, category: category, sortBy: sort)
            if page == 0 { wallpapers = results } else { wallpapers.append(contentsOf: results) }
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Wallpaper yükleme hatası: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func loadMore(category: WallpaperCategory?, sort: WallpaperSortOption) async {
        currentPage += 1
        await loadWallpapers(category: category, sort: sort, page: currentPage)
    }

    func search(query: String) async {
        guard !query.isEmpty else { await loadWallpapers(); return }
        isLoading = true
        do { wallpapers = try await service.searchWallpapers(query: query) } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
