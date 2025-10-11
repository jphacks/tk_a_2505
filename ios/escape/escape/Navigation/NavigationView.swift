//
//  NavigationView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

enum Tab {
    case home
    case map
    case settings
}

struct NavigationView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("nav.home", systemImage: "house.fill")
                }
                .tag(Tab.home)

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
