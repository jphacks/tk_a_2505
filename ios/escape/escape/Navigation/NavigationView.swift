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
                    Label("Home", systemImage: "house.fill")
                }

            MapView()
                .ignoresSafeArea()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    NavigationView()
}
