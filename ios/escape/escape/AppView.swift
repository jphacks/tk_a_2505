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
    @State var isCheckingAuth = true
    @State private var missionViewModel = MissionViewModel()
    @State private var appConfigViewModel = AppConfigViewModel()

    var body: some View {
        SwiftUI.Group {
            if appConfigViewModel.isCheckingConfig {
                ProgressView()
                    .onAppear {
                        Task {
                            await appConfigViewModel.checkAppConfig()
                        }
                    }
            } else if appConfigViewModel.isMaintenanceMode {
                MaintenanceView(message: appConfigViewModel.appConfig?.getMaintenanceMessage())
            } else if appConfigViewModel.requiresForceUpdate {
                ForceUpdateView(message: appConfigViewModel.appConfig?.getForceUpdateMessage())
            } else {
                // Normal app flow
                normalAppView
            }
        }
    }

    private var normalAppView: some View {
        SwiftUI.Group {
            if isCheckingAuth {
                ProgressView()
            } else if isAuthenticated {
                NavigationView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            Task {
                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        isAuthenticated = state.session != nil
                        isCheckingAuth = false

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
}

#Preview("AppView - English") {
    AppView().environment(\.locale, .init(identifier: "en"))
}

#Preview("AppView - Japanese") {
    AppView().environment(\.locale, .init(identifier: "ja"))
}
