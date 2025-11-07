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
    @State private var showQRScanner = false

    var body: some View {
        VStack(spacing: 24) {
            // Description
            Text("group.join.description", bundle: .main)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            // Invite Code Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("group.join.invite_code", bundle: .main)
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
                            showQRScanner = true
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(Color("brandOrange"))
                                .frame(width: 40, height: 40)
                                .background(Color("brandOrange").opacity(0.1))
                                .cornerRadius(20)
                        }
                    }

                    // Format Help
                    VStack(alignment: .leading, spacing: 8) {
                        Text("group.join.format_label", bundle: .main)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text("group.join.format_rule_1", bundle: .main)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("group.join.format_rule_2", bundle: .main)
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

                            Text(
                                isValidInviteCode
                                    ? String(localized: "group.join.valid_format", bundle: .main)
                                    : String(localized: "group.join.invalid_format", bundle: .main)
                            )
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

                        Text(
                            groupViewModel.isJoiningGroup
                                ? String(localized: "group.join.joining", bundle: .main)
                                : String(localized: "group.join.button", bundle: .main)
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        joinButtonEnabled ? Color("brandOrange") : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .disabled(!joinButtonEnabled)
            }
            .padding(.horizontal)

            // Info Section
            VStack(spacing: 8) {
                Text("group.join.tips_title", bundle: .main)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    JoinGroupInfoRow(
                        icon: "message", text: String(localized: "group.join.tip_receive", bundle: .main)
                    )
                    JoinGroupInfoRow(
                        icon: "shield", text: String(localized: "group.join.tip_approval", bundle: .main)
                    )
                    JoinGroupInfoRow(
                        icon: "person.3", text: String(localized: "group.join.tip_activities", bundle: .main)
                    )
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
        .sheet(isPresented: $showQRScanner) {
            QRCodeScannerView(scannedCode: $groupViewModel.joinGroupInviteCode)
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
