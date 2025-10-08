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

    var body: some View {
        Group {
            if isAuthenticated {
                ProfileView()
            } else {
                AuthView()
            }
        }
        .task {
            for await state in supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    isAuthenticated = state.session != nil
                }
            }
        }
    }
}

#Preview {
    AppView()
}
