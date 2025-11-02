//
//  CreateGroupView.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import SwiftUI

struct CreateGroupView: View {
    @Bindable var groupViewModel: GroupViewModel
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isDescriptionFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header Info
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("brandOrange"))

                Text("group.create.title", bundle: .main)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("group.create.description", bundle: .main)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Form
            VStack(spacing: 20) {
                // Group Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("group.create.name_label", bundle: .main)
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField(String(localized: "group.create.name_placeholder", bundle: .main), text: $groupViewModel.createGroupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            isDescriptionFieldFocused = true
                        }

                    Text("\(groupViewModel.createGroupName.count)/100")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Group Description Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("group.create.description_label", bundle: .main)
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField(String(localized: "group.create.description_placeholder", bundle: .main), text: $groupViewModel.createGroupDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3 ... 6)
                        .focused($isDescriptionFieldFocused)

                    Text("group.create.description_hint", bundle: .main)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Error Message
            if let errorMessage = groupViewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                .transition(.opacity)
            }

            // Create Button
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await groupViewModel.createGroup()
                    }
                }) {
                    HStack {
                        if groupViewModel.isCreatingGroup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus")
                        }

                        Text(groupViewModel.isCreatingGroup ? String(localized: "group.create.creating", bundle: .main) : String(localized: "group.create.button", bundle: .main))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        createButtonEnabled ? Color("brandOrange") : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!createButtonEnabled)

                // Info
                VStack(spacing: 8) {
                    Text("group.create.after_title", bundle: .main)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        CreateGroupInfoRow(icon: "key", text: String(localized: "group.create.after_invite_code", bundle: .main))
                        CreateGroupInfoRow(icon: "crown", text: String(localized: "group.create.after_owner", bundle: .main))
                        CreateGroupInfoRow(icon: "person.badge.plus", text: String(localized: "group.create.after_max_members", bundle: .main))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            hideKeyboard()
        }
        .onChange(of: groupViewModel.errorMessage) { _, _ in
            if groupViewModel.errorMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    groupViewModel.clearError()
                }
            }
        }
    }

    private var createButtonEnabled: Bool {
        !groupViewModel.isCreatingGroup &&
            groupViewModel.isValidGroupName(groupViewModel.createGroupName)
    }

    private func hideKeyboard() {
        isNameFieldFocused = false
        isDescriptionFieldFocused = false
    }
}

struct CreateGroupInfoRow: View {
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
    CreateGroupView(groupViewModel: GroupViewModel())
}
