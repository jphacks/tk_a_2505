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
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("グループ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
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
            .alert("グループから退出", isPresented: $showingLeaveAlert) {
                Button("退出", role: .destructive) {
                    Task {
                        await groupViewModel.leaveCurrentGroup()
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("本当にこのグループから退出しますか？")
            }
            .alert("グループを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    Task {
                        await groupViewModel.deleteGroup()
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このグループを完全に削除しますか？この操作は取り消せません。")
            }
        }
    }
}

// MARK: - Group Header View

struct GroupHeaderView: View {
    let group: GroupWithDetails

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
                Text(group.group.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let description = group.group.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Member Count and Role
                HStack(spacing: 16) {
                    Label("\(group.memberCount)/\(group.group.maxMembers)", systemImage: "person.3")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let role = group.currentUserRole {
                        Text(role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("brandOrange").opacity(0.2))
                            .foregroundColor(Color("brandOrange"))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Group Action Buttons View

struct GroupActionButtonsView: View {
    let group: GroupWithDetails
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
                    Text("招待コードを共有")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("brandOrange"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Management Buttons (for owners/admins)
            if groupViewModel.isCurrentUserOwner {
                HStack(spacing: 12) {
                    // Edit Group Button (placeholder)
                    Button(action: {
                        // TODO: Implement group editing
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("編集")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .disabled(true) // Disabled until editing is implemented

                    // Delete Group Button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("削除")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
            } else {
                // Leave Group Button
                Button(action: {
                    showingLeaveAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle")
                        Text("グループから退出")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
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
                Text("メンバー")
                    .font(.headline)

                Spacer()

                Text("\(groupViewModel.groupMembers.count)人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if groupViewModel.isLoading {
                ProgressView("メンバーを読み込み中...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if groupViewModel.groupMembers.isEmpty {
                Text("メンバーが見つかりません")
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
        .cornerRadius(12)
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: GroupMemberWithUser
    @Bindable var groupViewModel: GroupViewModel
    @State private var showingRoleMenu = false

    var body: some View {
        HStack(spacing: 12) {
            // Member Avatar
            Circle()
                .fill(Color("brandOrange").opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.user.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(Color("brandOrange"))
                )

            // Member Info
            VStack(alignment: .leading, spacing: 2) {
                Text(member.user.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Text("参加日: \(member.member.joinedAt.formatted(date: .abbreviated, time: .omitted))")
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
                    member.member.role == .owner ? Color("brandOrange").opacity(0.2) :
                        member.member.role == .admin ? Color.blue.opacity(0.2) :
                        Color(.systemGray5)
                )
                .foregroundColor(
                    member.member.role == .owner ? Color("brandOrange") :
                        member.member.role == .admin ? .blue :
                        .secondary
                )
                .cornerRadius(6)

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

                    Button("メンバーを削除", role: .destructive) {
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
        .cornerRadius(8)
    }
}

// MARK: - Group Stats View (Placeholder)

struct GroupStatsView: View {
    let group: GroupWithDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("グループ統計")
                .font(.headline)

            VStack(spacing: 12) {
                StatRowView(title: "総ミッション数", value: "0", icon: "target")
                StatRowView(title: "総バッジ数", value: "0", icon: "shield.fill")
                StatRowView(title: "アクティブメンバー", value: "\(group.memberCount)", icon: "person.3.fill")
            }

            Text("※ ランキング機能は今後実装予定です")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    let group: GroupWithDetails
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 48))
                        .foregroundColor(Color("brandOrange"))

                    Text("招待コード")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("このコードを友達に共有して、グループに招待しましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Invite Code Display
                VStack(spacing: 16) {
                    Text(group.group.inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("brandOrange"))
                        .padding()
                        .background(Color("brandOrange").opacity(0.1))
                        .cornerRadius(12)

                    Button(action: {
                        UIPasteboard.general.string = group.group.inviteCode
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("コピー")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("brandOrange"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Info
                VStack(spacing: 8) {
                    Text("📋 使い方")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        GroupDetailInfoRow(icon: "1.circle", text: "上記のコードをコピー")
                        GroupDetailInfoRow(icon: "2.circle", text: "友達にメッセージで送信")
                        GroupDetailInfoRow(icon: "3.circle", text: "友達がアプリで入力して参加")
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
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
