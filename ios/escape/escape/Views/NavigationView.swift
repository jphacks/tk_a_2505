//
//  NavigationView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

enum Tab {
    case home
    case map
    case settings
}

struct NavigationView: View {
    @StateObject private var tabSelection = TabSelection()

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            HomeView()
                .tabItem {
                    Label("nav.home", systemImage: "house.fill")
                }
                .tag(Tab.home)
                .environmentObject(tabSelection)

            MapView()
                .ignoresSafeArea()
                .tabItem {
                    Label("nav.map", systemImage: "map.fill")
                }
                .tag(Tab.map)

            SettingView()
                .tabItem {
                    Label("nav.setting", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview("NavigationView - English") {
    NavigationView().environment(\.locale, .init(identifier: "en"))
}

#Preview("NavigationView - Japanese") {
    NavigationView().environment(\.locale, .init(identifier: "ja"))
}
