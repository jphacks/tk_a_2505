//
//  SettingView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        ProfileView()
    }
}

#Preview("SettingView - English") {
    SettingView().environment(\.locale, .init(identifier: "en"))
}

#Preview("SettingView - Japanese") {
    SettingView().environment(\.locale, .init(identifier: "ja"))
}
