// GalleryView.swift
// MacOS-Dino – Professional Gallery (HTML pixel-perfect match)

import SwiftUI

// MARK: - Gallery Navigation Tab

enum GalleryNavTab: String, CaseIterable {
    case hot       = "Hot"
    case new       = "New"
    case favorites = "Favorites"
    case uploads   = "My Uploads"
    case downloaded = "Downloaded"

    var icon: String {
        switch self {
        case .hot:        return "flame.fill"
        case .new:        return "sparkles"
        case .favorites:  return "heart.fill"
        case .uploads:    return "icloud.and.arrow.up.fill"
        case .downloaded: return "arrow.down.circle.fill"
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

    // HTML design tokens
    private let bg         = Color(red: 0.063, green: 0.086, blue: 0.133)   // #101622
    private let mainBg     = Color(red: 0.039, green: 0.059, blue: 0.094)   // #0a0f18
    private let surface    = Color(red: 0.102, green: 0.133, blue: 0.204)   // #1a2234
    private let borderDark = Color(red: 0.176, green: 0.227, blue: 0.329)   // #2d3a54
    private let primary    = Color(red: 0.051, green: 0.349, blue: 0.949)   // #0d59f2
    private let textSec    = Color(red: 0.6,   green: 0.65,  blue: 0.76)
    private let textDim    = Color(red: 0.38,  green: 0.44,  blue: 0.56)

    enum ViewMode { case grid, list }

    var body: some View {
        HStack(spacing: 0) {
            leftSidebar
            mainContent
            // right panel only if something selected
            if let wallpaper = selectedWallpaper {
                Rectangle().fill(borderDark).frame(width: 1)
                WallpaperDetailView(wallpaper: wallpaper)
                    .environmentObject(engine)
                    .frame(width: 320)
            }
        }
        .background(mainBg)
        .preferredColorScheme(.dark)
        .task { await viewModel.loadWallpapers(sort: .hot) }
    }

    // MARK: - Computed wallpapers

    private var displayableWallpapers: [Wallpaper] {
        var all = localManager.allLocalWallpapers
        let localIDs = Set(all.map { $0.id })
        for wp in viewModel.wallpapers where !localIDs.contains(wp.id) { all.append(wp) }

        if !searchText.isEmpty {
            all = all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if !selectedCategories.isEmpty {
            all = all.filter { selectedCategories.contains($0.category) }
        }
        if !selectedRatios.isEmpty {
            all = all.filter { selectedRatios.contains($0.aspectRatio) }
        }
        switch selectedNavTab {
        case .hot:        all.sort { $0.popularityScore > $1.popularityScore }
        case .new:        all.sort { $0.createdAt > $1.createdAt }
        case .favorites:  all = all.filter { $0.isFeatured }
        case .downloaded: all = all.filter { $0.isDownloaded }
        case .uploads:    all = all.filter { $0.category == .personal }
        }
        return all
    }

    // MARK: - Left Sidebar (w-72 = 288pt)

    private var leftSidebar: some View {
        VStack(spacing: 0) {
            // ─── Header (logo + search + nav) ─────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                // Logo
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Wallpapers")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Professional Suite")
                            .font(.system(size: 10))
                            .foregroundStyle(textDim)
                    }
                    Spacer()
                }
                .padding(.bottom, 24)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(textDim)
                    TextField("Search wallpapers...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(surface))
                .padding(.bottom, 20)

                // Nav items
                VStack(spacing: 2) {
                    ForEach(GalleryNavTab.allCases, id: \.self) { tab in
                        navItem(tab: tab)
                    }
                }
            }
            .padding(24)
            .overlay(Rectangle().fill(borderDark).frame(height: 1), alignment: .bottom)

            // ─── Filters (scrollable) ──────────────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Categories
                    filterSection(title: "Categories") {
                        ForEach([WallpaperCategory.cartoon, .game, .animation, .nature,
                                  .abstract, .cityscape, .deepSpace, .minimal]) { cat in
                            filterCheckbox(label: cat.displayName,
                                           isOn: selectedCategories.contains(cat)) {
                                toggle(&selectedCategories, item: cat)
                            }
                        }
                    }

                    // Ratio
                    filterSection(title: "Ratio") {
                        ForEach([AspectRatio.widescreen, .ultrawide, .standard]) { ratio in
                            filterCheckbox(label: ratio.rawValue,
                                           isOn: selectedRatios.contains(ratio)) {
                                toggle(&selectedRatios, item: ratio)
                            }
                        }
                    }
                }
                .padding(24)
            }

            Spacer(minLength: 0)

            // ─── Footer (Refresh Data) ─────────────────────────────────────
            VStack(spacing: 0) {
                Rectangle().fill(borderDark).frame(height: 1)
                Button {
                    Task { await viewModel.loadWallpapers(sort: selectedNavTab == .new ? .new : .hot) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 13))
                        Text("Refresh Data").font(.system(size: 13))
                    }
                    .foregroundStyle(textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(surface))
                }
                .buttonStyle(.plain)
                .padding(24)
            }
        }
        .frame(width: 288)
        .background(bg)
    }

    // MARK: - Sidebar Helpers

    private func navItem(tab: GalleryNavTab) -> some View {
        let isActive = selectedNavTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedNavTab = tab }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(isActive ? primary : textSec)
                    .frame(width: 18)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? primary : textSec)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? primary.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(textDim)
            content()
        }
    }

    private func filterCheckbox(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOn ? primary : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(isOn ? primary : borderDark, lineWidth: 1.5))
                        .frame(width: 16, height: 16)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(isOn ? .white : textSec)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle<T: Hashable>(_ set: inout Set<T>, item: T) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discovery")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Browsing \(displayableWallpapers.count) high-quality wallpapers")
                        .font(.system(size: 13))
                        .foregroundStyle(textSec)
                }
                Spacer()
                // Grid / List toggle
                HStack(spacing: 2) {
                    toggleBtn(mode: .grid, icon: "square.grid.2x2.fill")
                    toggleBtn(mode: .list, icon: "list.bullet")
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8).fill(surface))
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Grid
            if displayableWallpapers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 24)],
                        spacing: 24
                    ) {
                        ForEach(displayableWallpapers) { wp in
                            WallpaperCard(
                                wallpaper: wp,
                                isSelected: selectedWallpaper?.id == wp.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedWallpaper = (selectedWallpaper?.id == wp.id) ? nil : wp
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(minWidth: 480)
        .background(mainBg)
    }

    private func toggleBtn(mode: ViewMode, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(viewMode == mode ? .white : textDim)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewMode == mode ? primary.opacity(0.5) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(textDim)
            Text("No Wallpapers Found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textSec)
            Text("Try different filters or search terms")
                .font(.system(size: 12))
                .foregroundStyle(textDim)
            Spacer()
        }
    }
}

// MARK: - WallpaperServiceViewModel

@MainActor
final class WallpaperServiceViewModel: ObservableObject {
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = WallpaperService.shared
    private var currentPage = 0

    func loadWallpapers(category: WallpaperCategory? = nil,
                        sort: WallpaperSortOption = .hot,
                        page: Int = 0) async {
        isLoading = true
        currentPage = page
        do {
            let results = try await service.fetchWallpapers(page: page, category: category, sortBy: sort)
            if page == 0 { wallpapers = results } else { wallpapers.append(contentsOf: results) }
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Wallpaper load error: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func search(query: String) async {
        guard !query.isEmpty else { await loadWallpapers(); return }
        isLoading = true
        do { wallpapers = try await service.searchWallpapers(query: query) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
