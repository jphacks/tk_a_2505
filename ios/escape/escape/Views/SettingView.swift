//
//  SettingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

struct SettingView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        // Profile Avatar
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(viewModel.name.prefix(1).uppercased())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                            )

                        // Profile Info
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.name.isEmpty {
                                Text("setting.loading")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            } else {
                                Text(viewModel.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            Text("setting.profile_description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    // Edit Profile Navigation
                    NavigationLink {
                        ProfileEditView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("setting.edit_profile")
                        }
                    }
                } header: {
                    Text("setting.profile_section")
                }

                // Developer Section
                Section {
                    NavigationLink {
                        DevView()
                    } label: {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("dev.title")
                        }
                    }
                } header: {
                    Text("setting.developer_section")
                }

                // Account Section
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("profile.sign_out")
                        }
                    }
                } header: {
                    Text("setting.account_section")
                }
                .confirmationDialog("setting.logout_confirmation", isPresented: $showLogoutConfirmation) {
                    Button("profile.sign_out", role: .destructive) {
                        Task {
                            try? await viewModel.signOut()
                        }
                    }
                    Button("setting.cancel", role: .cancel) {}
                } message: {
                    Text("setting.logout_message")
                }
            }
            .navigationTitle("nav.setting")
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

// Separate Edit Profile View
struct ProfileEditView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextField("profile.username", text: $viewModel.name)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("setting.profile_info")
            }

            Section {
                Button {
                    Task {
                        await viewModel.updateProfile()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("profile.update_profile")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading || viewModel.name.isEmpty)
            }
        }
        .navigationTitle("setting.edit_profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("SettingView - English") {
    SettingView().environment(\.locale, .init(identifier: "en"))
}

#Preview("SettingView - Japanese") {
    SettingView().environment(\.locale, .init(identifier: "ja"))
}
