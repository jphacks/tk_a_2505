//
//  ProfileView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("profile.username", text: $viewModel.name)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button("profile.update_profile") {
                        Task {
                            await viewModel.updateProfile()
                        }
                    }
                    .bold()

                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("profile.profile")
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("profile.sign_out", role: .destructive) {
                        Task {
                            try? await viewModel.signOut()
                        }
                    }
                }
            })
        }
        .task {
            await viewModel.getInitialProfile()
        }
    }
}

#Preview("ProfileView - English") {
    ProfileView().environment(\.locale, .init(identifier: "en"))
}

#Preview("ProfileView - Japanese") {
    ProfileView().environment(\.locale, .init(identifier: "ja"))
}
