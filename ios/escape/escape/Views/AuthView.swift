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
        Group {
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

    private var loginView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and title
            VStack(spacing: 24) {
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                VStack(spacing: 8) {
                    Text("auth.welcome")
                        .font(.system(size: 28, weight: .bold))

                    Text("auth.sign_in_description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 48)

            Spacer()

            // Email input and button
            VStack(spacing: 16) {
                // Email field
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField("auth.email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .font(.body)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Sign in button
                Button(action: {
                    viewModel.signInButtonTapped()
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("auth.sign_in")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .frame(height: 52)
                    .background(viewModel.email.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading || viewModel.email.isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
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
                        Text("auth.check_inbox")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("auth.check_inbox_description")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
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
                    if case .success = result {
                        Button(action: {
                            openMailApp()
                        }) {
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

    private func openMailApp() {
        if let url = URL(string: "message://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview("AuthView - English") {
    AuthView().environment(\.locale, .init(identifier: "en"))
}

#Preview("AuthView - Japanese") {
    AuthView().environment(\.locale, .init(identifier: "ja"))
}
