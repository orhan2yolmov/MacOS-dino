// GalleryView.swift
// MacOS-Dino – Ana Galeri Görünümü (Modern Redesign)

import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    @StateObject private var wallpaperService = WallpaperServiceViewModel()

    @State private var selectedWallpaper: Wallpaper?
    @State private var searchText = ""
    @State private var selectedCategory: WallpaperCategory? = nil
    @State private var selectedRatio: AspectRatio? = nil
    @State private var sortOption: WallpaperSortOption = .hot
    @State private var viewMode: ViewMode = .grid
    @State private var showingAuth = false

    enum ViewMode {
        case grid, list
    }

    var body: some View {
        NavigationSplitView {
            // Sol Sidebar
            sidebarContent
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } content: {
            // Merkez: Wallpaper Grid
            mainContent
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: .infinity)
        } detail: {
            // Sağ: Detay Paneli
            detailPanel
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 340)
        }
        .searchable(text: $searchText, prompt: "Wallpaper ara...")
        .onChange(of: searchText) { _, newValue in
            Task { await wallpaperService.search(query: newValue) }
        }
        .task {
            await wallpaperService.loadWallpapers(category: selectedCategory, sort: sortOption)
        }
        .sheet(isPresented: $showingAuth) {
            LoginView()
                .frame(width: 400, height: 500)
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo + başlık
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text("MacOS-Dino")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            Divider().opacity(0.3)

            // Navigasyon listesi
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    // Keşfet
                    SidebarSection(title: "KEŞFET") {
                        SidebarButton(
                            icon: "flame.fill",
                            label: "Popüler",
                            color: .orange,
                            isActive: sortOption == .hot
                        ) {
                            sortOption = .hot
                            Task { await wallpaperService.loadWallpapers(category: selectedCategory, sort: .hot) }
                        }
                        SidebarButton(
                            icon: "sparkles",
                            label: "Yeni",
                            color: .blue,
                            isActive: sortOption == .new
                        ) {
                            sortOption = .new
                            Task { await wallpaperService.loadWallpapers(category: selectedCategory, sort: .new) }
                        }
                        SidebarButton(icon: "heart.fill", label: "Favoriler", color: .pink) {}
                        SidebarButton(icon: "icloud.and.arrow.up", label: "Yüklediklerim", color: .cyan) {}
                        SidebarButton(icon: "arrow.down.circle.fill", label: "İndirilenler", color: .green) {}
                    }

                    SidebarSection(title: "KATEGORİLER") {
                        ForEach(WallpaperCategory.allCases) { category in
                            SidebarButton(
                                icon: category.icon,
                                label: category.displayName,
                                color: category.color,
                                isActive: selectedCategory == category
                            ) {
                                withAnimation(.spring(duration: 0.25)) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                                Task {
                                    await wallpaperService.loadWallpapers(
                                        category: selectedCategory,
                                        sort: sortOption
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider().opacity(0.3)

            // Yenile butonu
            Button {
                Task { await wallpaperService.loadWallpapers(category: selectedCategory, sort: sortOption) }
            } label: {
                Label("Yenile", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(Color(red: 0.06, green: 0.07, blue: 0.12))
    }

    // MARK: - Main Content (Grid)

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Üst header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCategory?.displayName ?? "Keşfet")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(headerSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // Grid/List toggle
                HStack(spacing: 4) {
                    ForEach([(ViewMode.grid, "square.grid.2x2"), (ViewMode.list, "list.bullet")], id: \.0) { mode, icon in
                        Button {
                            withAnimation(.spring(duration: 0.2)) { viewMode = mode }
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(viewMode == mode ? .white : .white.opacity(0.35))
                                .frame(width: 30, height: 30)
                                .background(viewMode == mode ? .white.opacity(0.12) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Wallpaper grid
            if wallpaperService.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.blue)
                    Text("Yükleniyor...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            } else if wallpaperService.wallpapers.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("Wallpaper Bulunamadı")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Farklı filtreler deneyin")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.25))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: gridColumns,
                        spacing: 14
                    ) {
                        ForEach(wallpaperService.wallpapers) { wallpaper in
                            WallpaperCard(
                                wallpaper: wallpaper,
                                isSelected: selectedWallpaper?.id == wallpaper.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedWallpaper = wallpaper
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.14))
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        Group {
            if let wallpaper = selectedWallpaper {
                WallpaperDetailView(wallpaper: wallpaper)
                    .environmentObject(engine)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("Wallpaper Seçin")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Detayları ve önizlemeyi\nburada görüntüleyin")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.07, green: 0.08, blue: 0.13))
            }
        }
    }

    // MARK: - Helpers

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 14)]
    }

    private var headerSubtitle: String {
        let count = wallpaperService.wallpapers.count
        let cat = selectedCategory?.displayName ?? "tüm kategoriler"
        return "\(count) wallpaper · \(cat)"
    }
}

// MARK: - Sidebar Helper Views

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)

            content
        }
    }
}

private struct SidebarButton: View {
    let icon: String
    let label: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? color : .white.opacity(0.45))
                    .frame(width: 18)

                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.65))

                Spacer()

                if isActive {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isActive ? color.opacity(0.12) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
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
            let results = try await service.fetchWallpapers(
                page: page,
                category: category,
                sortBy: sort
            )
            if page == 0 {
                wallpapers = results
            } else {
                wallpapers.append(contentsOf: results)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore(category: WallpaperCategory?, sort: WallpaperSortOption) async {
        currentPage += 1
        await loadWallpapers(category: category, sort: sort, page: currentPage)
    }

    func search(query: String) async {
        guard !query.isEmpty else {
            await loadWallpapers()
            return
        }

        isLoading = true
        do {
            wallpapers = try await service.searchWallpapers(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
