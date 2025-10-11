//
//  NavigationView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

struct NavigationView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("nav.home", systemImage: "house.fill")
                }

            MapView()
                .tabItem {
                    Label("nav.map", systemImage: "map.fill")
                }

            SettingView()
                .tabItem {
                    Label("nav.setting", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview("NavigationView - English") {
    NavigationView().environment(\.locale, .init(identifier: "en"))
}

#Preview("NavigationView - Japanese") {
    NavigationView().environment(\.locale, .init(identifier: "ja"))
}
