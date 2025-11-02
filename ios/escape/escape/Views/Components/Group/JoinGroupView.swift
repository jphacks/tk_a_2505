//
//  JoinGroupView.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import SwiftUI

struct JoinGroupView: View {
    @Bindable var groupViewModel: GroupViewModel
    @FocusState private var isInviteCodeFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header Info
            VStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.system(size: 48))
                    .foregroundColor(Color("brandOrange"))

                Text("グループに参加")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("友達や家族から受け取った招待コードを入力して、グループに参加しましょう")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Invite Code Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("招待コード")
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Invite Code Input
                    HStack(spacing: 12) {
                        TextField("ABCD1234", text: $groupViewModel.joinGroupInviteCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled(true)
                            .focused($isInviteCodeFocused)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: groupViewModel.joinGroupInviteCode) { _, newValue in
                                // Auto-format to uppercase and limit to 8 characters
                                let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                if filtered != newValue {
                                    groupViewModel.joinGroupInviteCode = String(filtered.prefix(8))
                                }
                            }

                        // QR Code Scanner Button (placeholder for future implementation)
                        Button(action: {
                            // TODO: Implement QR code scanner
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(Color("brandOrange"))
                                .frame(width: 40, height: 40)
                                .background(Color("brandOrange").opacity(0.1))
                                .cornerRadius(8)
                        }
                        .disabled(true) // Disabled until QR scanner is implemented
                    }

                    // Format Help
                    VStack(alignment: .leading, spacing: 4) {
                        Text("招待コードの形式:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text("• 8文字の英数字（例: ABCD1234）")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("• 大文字・小文字は区別されません")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    // Validation Indicator
                    if !groupViewModel.joinGroupInviteCode.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: isValidInviteCode ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isValidInviteCode ? .green : .red)
                                .font(.caption)

                            Text(isValidInviteCode ? "有効な形式です" : "8文字の英数字を入力してください")
                                .font(.caption2)
                                .foregroundColor(isValidInviteCode ? .green : .red)
                        }
                        .transition(.opacity)
                    }
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

            // Join Button
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await groupViewModel.joinGroup()
                    }
                }) {
                    HStack {
                        if groupViewModel.isJoiningGroup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }

                        Text(groupViewModel.isJoiningGroup ? "参加中..." : "グループに参加")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        joinButtonEnabled ? Color("brandOrange") : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!joinButtonEnabled)

                // Example Code Display
                VStack(spacing: 8) {
                    Text("招待コードの例")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(["ABCD1234", "XYZ98765", "HELLO123"], id: \.self) { example in
                            Text(example)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                                .onTapGesture {
                                    groupViewModel.joinGroupInviteCode = example
                                }
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Info Section
            VStack(spacing: 8) {
                Text("💡 ヒント")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    JoinGroupInfoRow(icon: "message", text: "招待コードは友達から直接受け取ってください")
                    JoinGroupInfoRow(icon: "shield", text: "グループの管理者が参加を承認する場合があります")
                    JoinGroupInfoRow(icon: "person.3", text: "参加後はグループの活動が見れるようになります")
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)

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

    private var isValidInviteCode: Bool {
        groupViewModel.isValidInviteCode(groupViewModel.joinGroupInviteCode)
    }

    private var joinButtonEnabled: Bool {
        !groupViewModel.isJoiningGroup && isValidInviteCode
    }

    private func hideKeyboard() {
        isInviteCodeFocused = false
    }
}

struct JoinGroupInfoRow: View {
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
    JoinGroupView(groupViewModel: GroupViewModel())
}
