//
//  SettingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

struct SettingView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var groupViewModel = GroupViewModel()
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showingGroupBottomSheet = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        // Profile Avatar - shows badge image if selected, otherwise shows initial
                        UserAvatarView.profile(
                            username: viewModel.name,
                            badgeImageUrl: viewModel.profileBadgeImageUrl,
                            size: .medium
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

                // Group Section
                Section {
                    Button {
                        showingGroupBottomSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("setting.manage_groups")
                        }
                    }
                } header: {
                    Text("setting.group_section")
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

                    Button(role: .destructive) {
                        showDeleteAccountConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("setting.delete_account")
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
                .confirmationDialog("setting.delete_account_confirmation", isPresented: $showDeleteAccountConfirmation) {
                    Button("setting.delete_account", role: .destructive) {
                        Task {
                            try? await viewModel.deleteAccount()
                        }
                    }
                    Button("setting.cancel", role: .cancel) {}
                } message: {
                    Text("setting.delete_account_message")
                }
            }
            .navigationTitle("nav.setting")
            .sheet(isPresented: $showingGroupBottomSheet) {
                GroupBottomSheetView(groupViewModel: groupViewModel)
            }
        }
        .task {
            await viewModel.loadProfile()
            await groupViewModel.loadUserGroups()
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

            // Profile Photo Section - Select from unlocked badges
            Section {
                if viewModel.userBadges.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("setting.no_badges")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("setting.no_badges_hint")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical)
                        Spacer()
                    }
                } else {
                    // Badge Selection Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        // Option to clear badge (use initial)
                        Button {
                            viewModel.selectProfileBadge(nil)
                        } label: {
                            VStack(spacing: 4) {
                                UserAvatarView(
                                    username: viewModel.name,
                                    size: .medium,
                                    strokeColor: viewModel.selectedProfileBadgeId == nil ? Color.accentColor : Color.clear,
                                    strokeWidth: 3
                                )
                                Text("setting.profile_photo_default")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        // User's unlocked badges
                        ForEach(viewModel.userBadges) { badge in
                            if let badgeUUID = UUID(uuidString: badge.id) {
                                Button {
                                    viewModel.selectProfileBadge(badgeUUID)
                                } label: {
                                    VStack(spacing: 4) {
                                        UserAvatarView(
                                            username: badge.name,
                                            badgeImageUrl: badge.imageUrl,
                                            size: .medium,
                                            colors: [badge.color],
                                            strokeColor: viewModel.selectedProfileBadgeId == badgeUUID ? Color.accentColor : Color.clear,
                                            strokeWidth: 3
                                        )
                                        Text(badge.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("setting.profile_photo")
            } footer: {
                Text("setting.profile_photo_hint")
            }

            Section {
                Button {
                    Task {
                        await viewModel.updateProfile()
                        // Only dismiss if update was successful (no error)
                        if !viewModel.showError {
                            HapticFeedback.shared.success()
                            dismiss()
                        }
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview("SettingView - English") {
    SettingView().environment(\.locale, .init(identifier: "en"))
}

#Preview("SettingView - Japanese") {
    SettingView().environment(\.locale, .init(identifier: "ja"))
}
