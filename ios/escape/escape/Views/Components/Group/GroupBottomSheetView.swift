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
    @State private var randomBackgroundColor = Color("brandOrange")
    @Environment(\.dismiss) private var dismiss

    enum GroupTab: String, CaseIterable {
        case myGroups = "my_groups"
        case createGroup = "create_group"
        case joinGroup = "join_group"

        var title: String {
            switch self {
            case .myGroups:
                return String(localized: "group.tab.my_groups", bundle: .main)
            case .createGroup:
                return String(localized: "group.tab.create_group", bundle: .main)
            case .joinGroup:
                return String(localized: "group.tab.join_group", bundle: .main)
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
            ZStack {
                // Simple white background
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Simple Tab Selection
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
                        .cornerRadius(20)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                        // Content Section
                        VStack {
                            switch selectedTab {
                            case .myGroups:
                                MyGroupsView(groupViewModel: groupViewModel, selectedTab: $selectedTab)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                            case .createGroup:
                                CreateGroupView(groupViewModel: groupViewModel, selectedTab: $selectedTab)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                            case .joinGroup:
                                JoinGroupView(groupViewModel: groupViewModel)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .refreshable {
                    await groupViewModel.loadUserGroups()
                }
            }
            .navigationTitle(String(localized: "group.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "group.close", bundle: .main)) {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                }
            }
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
    @Binding var selectedTab: GroupBottomSheetView.GroupTab

    var body: some View {
        LazyVStack(spacing: 12) {
            if groupViewModel.isLoading {
                ProgressView(String(localized: "group.list.loading", bundle: .main))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if groupViewModel.userGroups.isEmpty {
                EmptyGroupsView(selectedTab: $selectedTab)
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
    @Binding var selectedTab: GroupBottomSheetView.GroupTab

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.3")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("group.empty.title", bundle: .main)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("group.empty.description", bundle: .main)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Simple suggestion cards
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .createGroup
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("brandOrange"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("group.empty.create_action", bundle: .main)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)

                            Text("group.empty.create_description", bundle: .main)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .joinGroup
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 20))
                            .foregroundColor(Color("brandOrange"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("group.empty.join_action", bundle: .main)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)

                            Text("group.empty.join_description", bundle: .main)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

// MARK: - Group Card View

struct GroupCardView: View {
    let group: TeamWithDetails
    @Bindable var groupViewModel: GroupViewModel
    @State private var showingGroupDetail = false

    var body: some View {
        Button(action: {
            Task {
                await groupViewModel.selectGroup(group)
                HapticFeedback.shared.lightImpact()
                showingGroupDetail = true
            }
        }) {
            HStack(spacing: 12) {
                // Simple Group Icon
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
                    Text(group.team.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let description = group.team.description {
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
                                .cornerRadius(8)
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
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingGroupDetail) {
            GroupDetailView(groupViewModel: groupViewModel)
        }
        .onChange(of: showingGroupDetail) { oldValue, newValue in
            // Haptic feedback when sheet is dismissed
            if oldValue && !newValue {
                HapticFeedback.shared.lightImpact()
            }
        }
    }
}

#Preview {
    GroupBottomSheetView(groupViewModel: GroupViewModel())
}
