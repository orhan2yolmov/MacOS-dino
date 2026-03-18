// GalleryView.swift
// MacOS-Dino – Ana Galeri Görünümü
// Sol sidebar (kategori, filtre) + Merkez grid + Sağ detay paneli
// Referans: Wallpapers Professional Suite tasarımı

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
            // Üst: Logo
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("MacOS-Dino")
                    .font(.headline)
            }
            .padding()

            // Navigasyon listesi
            List(selection: $sortOption) {
                Section {
                    NavigationLink(value: WallpaperSortOption.hot) {
                        Label("Popüler", systemImage: "flame.fill")
                    }
                    NavigationLink(value: WallpaperSortOption.new) {
                        Label("Yeni", systemImage: "sparkles")
                    }

                    Button {
                        // Favoriler
                    } label: {
                        Label("Favoriler", systemImage: "heart.fill")
                            .foregroundStyle(.pink)
                    }

                    Button {
                        // Yüklenenler
                    } label: {
                        Label("Yüklediklerim", systemImage: "icloud.and.arrow.up")
                    }

                    Button {
                        // İndirilenler
                    } label: {
                        Label("İndirilenler", systemImage: "arrow.down.circle.fill")
                    }
                }

                // Kategoriler
                Section("Kategoriler") {
                    ForEach(WallpaperCategory.allCases) { category in
                        Button {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                            Task {
                                await wallpaperService.loadWallpapers(
                                    category: selectedCategory,
                                    sort: sortOption
                                )
                            }
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                                Text(category.displayName)

                                Spacer()

                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // En-boy oranı
                Section("Oran") {
                    ForEach(AspectRatio.allCases) { ratio in
                        Button {
                            if selectedRatio == ratio {
                                selectedRatio = nil
                            } else {
                                selectedRatio = ratio
                            }
                        } label: {
                            HStack {
                                Text(ratio.displayName)
                                    .font(.caption)
                                Spacer()
                                if selectedRatio == ratio {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Alt: Refresh butonu
            Button {
                Task {
                    await wallpaperService.loadWallpapers(
                        category: selectedCategory,
                        sort: sortOption
                    )
                }
            } label: {
                Label("Verileri Yenile", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }

    // MARK: - Main Content (Grid)

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Üst bar: Başlık + View mode toggle
            HStack {
                VStack(alignment: .leading) {
                    Text("Keşfet")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Grid/List toggle
                Picker("Görünüm", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
            .padding()

            // Wallpaper grid
            if wallpaperService.isLoading {
                Spacer()
                ProgressView("Yükleniyor...")
                Spacer()
            } else if wallpaperService.wallpapers.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Wallpaper Bulunamadı",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Farklı filtreler deneyin veya arama yapın")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: gridColumns,
                        spacing: 16
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
                    .padding()
                }
            }
        }
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        Group {
            if let wallpaper = selectedWallpaper {
                WallpaperDetailView(wallpaper: wallpaper)
                    .environmentObject(engine)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Bir wallpaper seçin")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Detayları ve önizlemeyi burada görüntüleyebilirsiniz")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)]
    }

    private var headerSubtitle: String {
        let count = wallpaperService.wallpapers.count
        let categoryText = selectedCategory?.displayName ?? "tüm kategoriler"
        return "\(count) yüksek kaliteli \(categoryText) wallpaper"
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
