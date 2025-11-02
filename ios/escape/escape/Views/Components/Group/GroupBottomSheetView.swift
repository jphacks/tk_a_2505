//
//  GroupBottomSheetView.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import SwiftUI

struct GroupBottomSheetView: View {
    @Bindable var groupViewModel: GroupViewModel
    @State private var selectedTab: GroupTab = .myGroups

    enum GroupTab: String, CaseIterable {
        case myGroups = "my_groups"
        case createGroup = "create_group"
        case joinGroup = "join_group"

        var title: String {
            switch self {
            case .myGroups:
                return "マイグループ"
            case .createGroup:
                return "グループ作成"
            case .joinGroup:
                return "グループ参加"
            }
        }

        var icon: String {
            switch self {
            case .myGroups:
                return "person.3.fill"
            case .createGroup:
                return "plus.circle.fill"
            case .joinGroup:
                return "qrcode"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    // Title
                    HStack {
                        Text("グループ")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()
                    }
                    .padding(.horizontal)
                }

                // Tab Selection
                HStack(spacing: 0) {
                    ForEach(GroupTab.allCases, id: \.rawValue) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.title3)
                                    .foregroundColor(selectedTab == tab ? Color("brandOrange") : .secondary)

                                Text(tab.title)
                                    .font(.caption)
                                    .fontWeight(selectedTab == tab ? .medium : .regular)
                                    .foregroundColor(selectedTab == tab ? Color("brandOrange") : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == tab ? Color("brandOrange").opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Content
                ScrollView {
                    switch selectedTab {
                    case .myGroups:
                        MyGroupsView(groupViewModel: groupViewModel)
                    case .createGroup:
                        CreateGroupView(groupViewModel: groupViewModel)
                    case .joinGroup:
                        JoinGroupView(groupViewModel: groupViewModel)
                    }
                }
                .refreshable {
                    await groupViewModel.loadUserGroups()
                }
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            Task {
                await groupViewModel.loadUserGroups()
            }
        }
    }
}

// MARK: - My Groups View

struct MyGroupsView: View {
    @Bindable var groupViewModel: GroupViewModel

    var body: some View {
        LazyVStack(spacing: 12) {
            if groupViewModel.isLoading {
                ProgressView("グループを読み込み中...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if groupViewModel.userGroups.isEmpty {
                EmptyGroupsView()
            } else {
                ForEach(groupViewModel.userGroups, id: \.id) { group in
                    GroupCardView(group: group, groupViewModel: groupViewModel)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct EmptyGroupsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("まだグループに参加していません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("新しいグループを作成するか、\n招待コードでグループに参加してみましょう")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Group Card View

struct GroupCardView: View {
    let group: GroupWithDetails
    @Bindable var groupViewModel: GroupViewModel
    @State private var showingGroupDetail = false

    var body: some View {
        Button(action: {
            Task {
                await groupViewModel.selectGroup(group)
                showingGroupDetail = true
            }
        }) {
            HStack(spacing: 12) {
                // Group Icon
                Circle()
                    .fill(Color("brandOrange").opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.title3)
                            .foregroundColor(Color("brandOrange"))
                    )

                // Group Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.group.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let description = group.group.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Text(groupViewModel.memberCountText(for: group))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let role = group.currentUserRole {
                            Text(role.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("brandOrange").opacity(0.2))
                                .foregroundColor(Color("brandOrange"))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingGroupDetail) {
            GroupDetailView(groupViewModel: groupViewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    GroupBottomSheetView(groupViewModel: GroupViewModel())
}
