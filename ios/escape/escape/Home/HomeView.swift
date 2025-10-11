//
//  HomeView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("Home View")
    }
}

#Preview("HomeView - English") {
    HomeView().environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView().environment(\.locale, .init(identifier: "ja"))
}
