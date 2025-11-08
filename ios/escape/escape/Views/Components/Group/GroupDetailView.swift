//
//  GroupDetailView.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import SwiftUI

struct GroupDetailView: View {
    @Bindable var groupViewModel: GroupViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingInviteCode = false
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let group = groupViewModel.selectedGroup {
                        // Group Header
                        GroupHeaderView(group: group)

                        // Action Buttons
                        GroupActionButtonsView(
                            group: group,
                            groupViewModel: groupViewModel,
                            showingInviteCode: $showingInviteCode,
                            showingLeaveAlert: $showingLeaveAlert,
                            showingDeleteAlert: $showingDeleteAlert
                        )

                        // Members Section
                        GroupMembersView(groupViewModel: groupViewModel)

                        // Group Stats (placeholder for future ranking features)
                        if groupViewModel.canManageMembers {
                            GroupStatsView(group: group)
                        }
                    } else {
                        ProgressView(String(localized: "group.detail.loading", bundle: .main))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "group.detail.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "group.close", bundle: .main)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if groupViewModel.isCurrentUserOwner {
                        Menu {
                            Button(action: {
                                // TODO: Implement group editing
                            }) {
                                Label("group.detail.edit", systemImage: "pencil")
                            }
                            .disabled(true)

                            Divider()

                            Button(
                                role: .destructive,
                                action: {
                                    showingDeleteAlert = true
                                }
                            ) {
                                Label("group.detail.delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInviteCode) {
                if let group = groupViewModel.selectedGroup {
                    InviteCodeView(group: group)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .alert(
                String(localized: "group.detail.leave_alert_title", bundle: .main),
                isPresented: $showingLeaveAlert
            ) {
                Button(String(localized: "group.detail.leave_button", bundle: .main), role: .destructive) {
                    Task {
                        await groupViewModel.leaveCurrentGroup()
                        dismiss()
                    }
                }
                Button(String(localized: "setting.cancel", bundle: .main), role: .cancel) {}
            } message: {
                Text(String(localized: "group.detail.leave_alert_message", bundle: .main))
            }
            .alert(
                String(localized: "group.detail.delete_alert_title", bundle: .main),
                isPresented: $showingDeleteAlert
            ) {
                Button(String(localized: "group.detail.delete_button", bundle: .main), role: .destructive) {
                    Task {
                        await groupViewModel.deleteGroup()
                        dismiss()
                    }
                }
                Button(String(localized: "setting.cancel", bundle: .main), role: .cancel) {}
            } message: {
                Text(String(localized: "group.detail.delete_alert_message", bundle: .main))
            }
        }
    }
}

// MARK: - Group Header View

struct GroupHeaderView: View {
    let group: TeamWithDetails

    var body: some View {
        VStack(spacing: 16) {
            // Group Icon
            Circle()
                .fill(Color("brandOrange").opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("brandOrange"))
                )

            // Group Info
            VStack(spacing: 8) {
                Text(group.team.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let description = group.team.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Member Count and Role
                HStack(spacing: 16) {
                    Label("\(group.memberCount)/\(group.team.maxMembers)", systemImage: "person.3")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let role = group.currentUserRole {
                        Text(role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("brandOrange").opacity(0.2))
                            .foregroundColor(Color("brandOrange"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

// MARK: - Group Action Buttons View

struct GroupActionButtonsView: View {
    let group: TeamWithDetails
    @Bindable var groupViewModel: GroupViewModel
    @Binding var showingInviteCode: Bool
    @Binding var showingLeaveAlert: Bool
    @Binding var showingDeleteAlert: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Invite Code Button
            Button(action: {
                showingInviteCode = true
            }) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("group.detail.share_invite", bundle: .main)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("brandOrange"))
                .foregroundColor(.white)
                .cornerRadius(20)
            }

            // Leave Group Button (for non-owners)
            if !groupViewModel.isCurrentUserOwner {
                Button(action: {
                    showingLeaveAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle")
                        Text("group.detail.leave", bundle: .main)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(20)
                }
            }
        }
    }
}

// MARK: - Group Members View

struct GroupMembersView: View {
    @Bindable var groupViewModel: GroupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("group.detail.members", bundle: .main)
                    .font(.headline)

                Spacer()

                Text(
                    String(
                        format: String(localized: "group.detail.member_count", bundle: .main),
                        groupViewModel.groupMembers.count
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            if groupViewModel.isLoading {
                ProgressView(String(localized: "group.detail.loading_members", bundle: .main))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if groupViewModel.groupMembers.isEmpty {
                Text("group.detail.no_members", bundle: .main)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(groupViewModel.groupMembers, id: \.id) { member in
                        MemberRowView(member: member, groupViewModel: groupViewModel)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: TeamMemberWithUser
    @Bindable var groupViewModel: GroupViewModel
    @State private var showingRoleMenu = false
    @State private var showUserProfile = false

    var body: some View {
        HStack(spacing: 12) {
            // Member Avatar
            UserAvatarView(
                username: member.user.displayName,
                badgeImageUrl: groupViewModel.memberBadgeUrls[member.user.id],
                size: .small
            )

            // Member Info
            VStack(alignment: .leading, spacing: 2) {
                Text(member.user.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Text(
                    String(
                        format: String(localized: "group.detail.joined_date", bundle: .main),
                        member.member.joinedAt.formatted(date: .abbreviated, time: .omitted)
                    )
                )
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Role Badge
            Text(member.member.role.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    member.member.role == .owner
                        ? Color("brandOrange").opacity(0.2)
                        : member.member.role == .admin ? Color.blue.opacity(0.2) : Color(.systemGray5)
                )
                .foregroundColor(
                    member.member.role == .owner
                        ? Color("brandOrange") : member.member.role == .admin ? .blue : .secondary
                )
                .cornerRadius(8)

            // Action Menu (for owners/admins)
            if groupViewModel.canManageMembers && member.member.role != .owner {
                Menu {
                    if groupViewModel.isCurrentUserOwner {
                        ForEach(MemberRole.allCases.filter { $0 != .owner }, id: \.rawValue) { role in
                            Button(role.displayName) {
                                Task {
                                    await groupViewModel.updateMemberRole(member, newRole: role)
                                }
                            }
                        }
                        Divider()
                    }

                    Button(String(localized: "group.detail.remove_member", bundle: .main), role: .destructive) {
                        Task {
                            await groupViewModel.removeMember(member)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.shared.lightImpact()
            showUserProfile = true
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileBottomSheetView(userId: member.user.id)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Group Stats View (Placeholder)

struct GroupStatsView: View {
    let group: TeamWithDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("group.detail.stats_title", bundle: .main)
                .font(.headline)

            VStack(spacing: 12) {
                StatRowView(
                    title: String(localized: "group.detail.stats_total_missions", bundle: .main), value: "0",
                    icon: "target"
                )
                StatRowView(
                    title: String(localized: "group.detail.stats_total_badges", bundle: .main), value: "0",
                    icon: "shield.fill"
                )
                StatRowView(
                    title: String(localized: "group.detail.stats_active_members", bundle: .main),
                    value: "\(group.memberCount)", icon: "person.3.fill"
                )
            }

            Text("group.detail.stats_ranking_note", bundle: .main)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

struct StatRowView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("brandOrange"))
                .frame(width: 20)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Invite Code View

struct InviteCodeView: View {
    let group: TeamWithDetails
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("group.detail.invite_description", bundle: .main)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Invite Code Display
                    VStack(spacing: 16) {
                        // QR Code
                        if let qrImage = generateQRCode(from: group.team.inviteCode) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                        }

                        Text(group.team.inviteCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(Color("brandOrange"))
                            .padding()
                            .background(Color("brandOrange").opacity(0.1))
                            .cornerRadius(20)

                        Button(action: {
                            UIPasteboard.general.string = group.team.inviteCode
                        }) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("group.detail.copy", bundle: .main)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("brandOrange"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }

                    // Info
                    VStack(spacing: 8) {
                        Text("group.detail.usage_title", bundle: .main)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            GroupDetailInfoRow(
                                icon: "1.circle",
                                text: String(localized: "group.detail.usage_step1", bundle: .main)
                            )
                            GroupDetailInfoRow(
                                icon: "2.circle",
                                text: String(localized: "group.detail.usage_step2", bundle: .main)
                            )
                            GroupDetailInfoRow(
                                icon: "3.circle",
                                text: String(localized: "group.detail.usage_step3", bundle: .main)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "group.detail.invite_title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "group.close", bundle: .main)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

struct GroupDetailInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Color("brandOrange"))
                .frame(width: 12)

            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

#Preview {
    GroupDetailView(groupViewModel: GroupViewModel())
}
