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
                    TextField("Username", text: $controller.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                    TextField("Full name", text: $controller.fullName)
                        .textContentType(.name)
                    TextField("Website", text: $controller.website)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button("Update profile") {
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
            .navigationTitle("Profile")
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign out", role: .destructive) {
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

#Preview {
    ProfileView()
}
