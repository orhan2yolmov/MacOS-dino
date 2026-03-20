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
        case .new:        return "clock.fill"
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
    private let bg         = Color(red: 0.063, green: 0.086, blue: 0.133)   // #101622 (w-72 bg)
    private let mainBg     = Color(red: 0.039, green: 0.059, blue: 0.094)   // #0a0f18
    private let surface    = Color(red: 0.102, green: 0.133, blue: 0.204)   // #1a2234
    private let borderDark = Color(red: 0.176, green: 0.227, blue: 0.329)   // #2d3a54
    private let primary    = Color(red: 0.051, green: 0.349, blue: 0.949)   // #0d59f2
    private let textSlate200 = Color(red: 0.89, green: 0.91, blue: 0.95)
    private let textSec    = Color(red: 0.59, green: 0.64, blue: 0.73)      // slate-400
    private let textDim    = Color(red: 0.40, green: 0.45, blue: 0.54)      // slate-500

    enum ViewMode { case grid, list }

    var body: some View {
        HStack(spacing: 0) {
            leftSidebar
            mainContent
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
            // p-6 top section
            VStack(alignment: .leading, spacing: 0) {
                // Logo section: flex items-center gap-3 mb-8
                HStack(spacing: 12) {
                    // w-8 h-8 rounded-lg bg-primary
                    RoundedRectangle(cornerRadius: 8)
                        .fill(primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        )
                    // text elements
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Wallpapers")
                            .font(.system(size: 18, weight: .bold)) // text-lg font-bold
                            .foregroundStyle(.white)
                        Text("Professional Suite")
                            .font(.system(size: 12)) // text-xs
                            .foregroundStyle(textSec)
                    }
                    Spacer()
                }
                .padding(.bottom, 32)

                // Search: mb-6 relative
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14)) // text-sm
                        .foregroundStyle(textSec)
                    TextField("Search wallpapers...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14)) // text-sm
                        .foregroundStyle(textSlate200)
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 8) // py-2
                .background(RoundedRectangle(cornerRadius: 8).fill(surface))
                .padding(.bottom, 24)

                // Nav items: mb-8 space-y-1
                VStack(spacing: 4) {
                    ForEach(GalleryNavTab.allCases, id: \.self) { tab in
                        navItem(tab: tab)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Filters: space-y-6 overflow-y-auto pr-2
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Categories
                    filterSection(title: "Categories") {
                        ForEach([WallpaperCategory.cartoon, .game, .animation, .nature]) { cat in
                            filterCheckbox(label: cat.displayName,
                                           isOn: selectedCategories.contains(cat)) {
                                toggle(&selectedCategories, item: cat)
                            }
                        }
                    }

                    // Ratio
                    filterSection(title: "Ratio") {
                        filterCheckbox(label: "16:9 (Widescreen)", isOn: selectedRatios.contains(.widescreen)) { toggle(&selectedRatios, item: .widescreen) }
                        filterCheckbox(label: "21:9 (Ultrawide)", isOn: selectedRatios.contains(.ultrawide)) { toggle(&selectedRatios, item: .ultrawide) }
                        filterCheckbox(label: "4:3 (Standard)", isOn: selectedRatios.contains(.standard)) { toggle(&selectedRatios, item: .standard) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Spacer(minLength: 0)

            // Footer Button: mt-auto p-6 border-t
            VStack(spacing: 0) {
                Rectangle().fill(borderDark).frame(height: 1)
                Button {
                    Task { await viewModel.loadWallpapers(sort: selectedNavTab == .new ? .new : .hot) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14)) // text-sm
                        Text("Refresh Data")
                            .font(.system(size: 14, weight: .bold)) // text-sm font-bold
                    }
                    .foregroundStyle(textSlate200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12) // py-3
                    .background(RoundedRectangle(cornerRadius: 12).fill(surface)) // rounded-xl
                }
                .buttonStyle(.plain)
                .padding(24) // p-6
            }
        }
        .frame(width: 288) // w-72
        .background(bg)
        .overlay(Rectangle().fill(borderDark).frame(width: 1), alignment: .trailing)
    }

    // MARK: - Sidebar Helpers

    private func navItem(tab: GalleryNavTab) -> some View {
        let isActive = selectedNavTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedNavTab = tab }
        } label: {
            HStack(spacing: 12) { // gap-3
                Image(systemName: tab.icon)
                    .font(.system(size: 18)) // text-[20px] ish
                    .foregroundStyle(isActive ? primary : textSec)
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isActive ? .medium : .regular)) // text-sm
                    .foregroundStyle(isActive ? primary : textSec)
                Spacer()
            }
            .padding(.horizontal, 12) // px-3
            .padding(.vertical, 8)    // py-2
            .background(
                RoundedRectangle(cornerRadius: 8) // rounded-lg
                    .fill(isActive ? primary.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) { // mb-3
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold)) // text-xs font-bold
                .tracking(1.2) // tracking-wider
                .foregroundStyle(textDim) // text-slate-500
            VStack(alignment: .leading, spacing: 8) { // space-y-2
                content()
            }
        }
    }

    private func filterCheckbox(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) { // gap-3
                ZStack {
                    RoundedRectangle(cornerRadius: 4) // rounded
                        .fill(isOn ? surface : surface) // bg-surface-dark
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderDark, lineWidth: 1))
                        .frame(width: 16, height: 16)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(primary) // text-primary
                    }
                }
                Text(label)
                    .font(.system(size: 14)) // text-sm
                    .foregroundStyle(isOn ? textSlate200 : textSec) // text-slate-400 group-hover:text-slate-200
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle<T: Hashable>(_ set: inout Set<T>, item: T) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header: mb-8 flex
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discovery")
                        .font(.system(size: 30, weight: .bold)) // text-3xl
                        .foregroundStyle(.white)
                    Text("Browsing \(displayableWallpapers.count) high-quality wallpapers")
                        .font(.system(size: 16)) // text-base placeholder
                        .foregroundStyle(textSec) // text-slate-400
                }
                Spacer()
                // Grid / List toggle: flex gap-2
                HStack(spacing: 8) {
                    toggleBtn(mode: .grid, icon: "square.grid.2x2.fill")
                    toggleBtn(mode: .list, icon: "list.bullet")
                }
            }
            .padding(.horizontal, 32) // p-8
            .padding(.top, 32)
            .padding(.bottom, 32)

            // Grid: grid gap-6
            if displayableWallpapers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 24)], // gap-6 (24pt)
                        spacing: 24
                    ) {
                        ForEach(displayableWallpapers) { wp in
                            WallpaperCard(
                                wallpaper: wp,
                                isSelected: selectedWallpaper?.id == wp.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
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
                .font(.system(size: 16))
                .foregroundStyle(viewMode == mode ? .white : textSec)
                .frame(width: 32, height: 32) // p-2ish
                .background(
                    RoundedRectangle(cornerRadius: 8) // rounded-lg
                        .fill(surface) // bg-surface-dark
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
