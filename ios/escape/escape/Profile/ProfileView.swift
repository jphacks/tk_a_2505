//
//  ProfileView.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import Supabase
import SwiftUI

struct ProfileView: View {
    @State private var controller = ProfileController()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("profile.username", text: $controller.name)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button("profile.update_profile") {
                        Task {
                            await controller.updateProfile()
                        }
                    }
                    .bold()

                    if controller.isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("profile.profile")
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("profile.sign_out", role: .destructive) {
                        Task {
                            try? await controller.signOut()
                        }
                    }
                }
            })
        }
        .task {
            await controller.getInitialProfile()
        }
    }
}

#Preview("ProfileView - English") {
    ProfileView().environment(\.locale, .init(identifier: "en"))
}

#Preview("ProfileView - Japanese") {
    ProfileView().environment(\.locale, .init(identifier: "ja"))
}
