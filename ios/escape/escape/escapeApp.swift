//
//  escapeApp.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import SwiftUI

@main
struct escapeApp: App {
    @State private var missionStateManager = MissionStateManager()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(missionStateManager)
        }
    }
}
