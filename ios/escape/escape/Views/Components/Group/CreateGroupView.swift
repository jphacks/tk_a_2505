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

                Text("新しいグループを作成")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("グループを作成して、友達や家族と防災訓練の成果を共有しましょう")
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
                    Text("グループ名")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("例: 田中家防災チーム", text: $groupViewModel.createGroupName)
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
                    Text("説明（任意）")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("例: 家族みんなで楽しく防災訓練", text: $groupViewModel.createGroupDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3 ... 6)
                        .focused($isDescriptionFieldFocused)

                    Text("グループの目的や特徴を簡潔に説明してください")
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

                        Text(groupViewModel.isCreatingGroup ? "作成中..." : "グループを作成")
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
                    Text("📋 作成後について")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        CreateGroupInfoRow(icon: "key", text: "招待コードが自動生成されます")
                        CreateGroupInfoRow(icon: "crown", text: "あなたがグループのオーナーになります")
                        CreateGroupInfoRow(icon: "person.badge.plus", text: "最大50人まで招待できます")
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
