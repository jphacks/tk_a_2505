//
//  AppView.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import Supabase
import SwiftUI

struct AppView: View {
    @State var isAuthenticated = false
    @State private var missionViewModel = MissionViewModel()

    var body: some View {
        Group {
            if isAuthenticated {
                NavigationView()
            } else {
                AuthView()
            }
        }
        .task {
            for await state in supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    isAuthenticated = state.session != nil

                    // When user is authenticated, ensure they have an active mission
                    if isAuthenticated, let session = state.session {
                        Task {
                            await missionViewModel.ensureUserHasActiveMission(userId: session.user.id)
                        }
                    }
                }
            }
        }
    }
}

#Preview("AppView - English") {
    AppView().environment(\.locale, .init(identifier: "en"))
}

#Preview("AppView - Japanese") {
    AppView().environment(\.locale, .init(identifier: "ja"))
}
