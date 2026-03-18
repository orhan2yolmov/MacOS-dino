// MenuBarPopover.swift
// MacOS-Dino – Menu Bar Popover Sarmalayıcı
// Liquid Glass stili ile MenuBarExtra window

import SwiftUI

struct MenuBarPopover: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    var body: some View {
        MenuBarView()
            .environmentObject(engine)
            .environmentObject(auth)
            .background(.ultraThinMaterial)
    }
}
