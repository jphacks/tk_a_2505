//
//  AuthView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

struct AuthView: View {
    @State private var viewModel = AuthViewModel()

    var body: some View {
        SwiftUI.Group {
            if let result = viewModel.result {
                // Result screen
                resultView(result: result)
            } else {
                // Login form
                loginView
            }
        }
        .onOpenURL(perform: { url in
            Task {
                await viewModel.handleDeepLink(url: url)
            }
        })
    }

    private var isSignInDisabled: Bool {
        viewModel.isLoading || viewModel.email.isEmpty ||
            (viewModel.usePasswordAuth && viewModel.password.isEmpty) ||
            (viewModel.isSignUp && !viewModel.passwordsMatch)
    }

    private var loginView: some View {
        VStack(spacing: 0) {
            // Header
            AuthHeader()

            // Form
            VStack(spacing: 16) {
                // Auth mode toggle
                AuthModeToggle(
                    usePasswordAuth: $viewModel.usePasswordAuth,
                    onPasswordAuthChange: { newValue in
                        if !newValue {
                            viewModel.isSignUp = false
                        }
                    }
                )

                // Magic link description (only show when magic link is selected)
                if !viewModel.usePasswordAuth {
                    Text("auth.magic_link_description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                // Form fields
                AuthFormFields(
                    email: $viewModel.email,
                    password: $viewModel.password,
                    confirmPassword: $viewModel.confirmPassword,
                    usePasswordAuth: viewModel.usePasswordAuth,
                    isSignUp: viewModel.isSignUp,
                    passwordsMatch: viewModel.passwordsMatch
                )

                // Sign in/up button
                PrimaryButton(
                    title: viewModel.isSignUp ? "auth.sign_up" : "auth.sign_in",
                    isLoading: viewModel.isLoading,
                    isDisabled: isSignInDisabled,
                    action: { viewModel.signInButtonTapped() }
                )
                .padding(.top, 8)

                // Toggle sign up/sign in (only show for password auth)
                if viewModel.usePasswordAuth {
                    AuthToggleLink(isSignUp: viewModel.isSignUp) {
                        withAnimation(.none) {
                            viewModel.isSignUp.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // Terms and Privacy Policy
            AuthFooter(openURL: openURL)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func resultView(result: Result<Void, Error>) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon
                switch result {
                case .success:
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                case .failure:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                }

                // Message
                VStack(spacing: 12) {
                    switch result {
                    case .success:
                        if viewModel.lastAuthType == .passwordSignUp {
                            Text("auth.verify_email")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text("auth.verify_email_description")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        } else {
                            Text("auth.check_inbox")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text("auth.check_inbox_description")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    case let .failure(error):
                        Text("auth.error")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    if case .success = result, viewModel.lastAuthType != .passwordSignIn {
                        Menu {
                            Button(action: { openMailApp(scheme: "message://") }) {
                                Label("Mail", systemImage: "envelope")
                            }
                            Button(action: { openMailApp(scheme: "googlegmail://") }) {
                                Label("Gmail", systemImage: "envelope")
                            }
                            Button(action: { openMailApp(scheme: "ms-outlook://") }) {
                                Label("Outlook", systemImage: "envelope")
                            }
                            Button(action: { openMailApp(scheme: "ymail://") }) {
                                Label("Yahoo Mail", systemImage: "envelope")
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("auth.open_mail")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .frame(height: 52)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        viewModel.reset()
                    }) {
                        HStack {
                            Spacer()
                            Text("auth.back")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(height: 52)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func openMailApp(scheme: String) {
        if let url = URL(string: scheme) {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

#Preview("AuthView - English") {
    AuthView().environment(\.locale, .init(identifier: "en"))
}

#Preview("AuthView - Japanese") {
    AuthView().environment(\.locale, .init(identifier: "ja"))
}
