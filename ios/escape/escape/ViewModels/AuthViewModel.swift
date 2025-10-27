//
//  AuthViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var usePasswordAuth = false
    var isSignUp = false
    var isLoading = false
    var result: Result<Void, Error>?
    var lastAuthType: AuthType = .magicLink

    enum AuthType {
        case magicLink
        case passwordSignIn
        case passwordSignUp
    }

    // MARK: - Dependencies

    private let authService: AuthSupabase

    // MARK: - Initialization

    init(authService: AuthSupabase = AuthSupabase()) {
        self.authService = authService
    }

    // MARK: - Actions

    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if isSignUp && usePasswordAuth {
                    lastAuthType = .passwordSignUp
                    try await authService.signUp(
                        email: email,
                        password: password,
                        redirectTo: URL(
                            string: "io.supabase.user-management://login-callback"
                        )
                    )
                    result = .success(())
                } else if usePasswordAuth {
                    lastAuthType = .passwordSignIn
                    try await authService.signInWithPassword(
                        email: email,
                        password: password
                    )
                    // Don't show result page for password sign-in
                } else {
                    lastAuthType = .magicLink
                    try await authService.signInWithOTP(
                        email: email,
                        redirectTo: URL(
                            string: "io.supabase.user-management://login-callback"
                        )
                    )
                    result = .success(())
                }
            } catch {
                result = .failure(error)
            }
        }
    }

    func handleDeepLink(url: URL) async {
        do {
            try await authService.handleSession(from: url)
        } catch {
            result = .failure(error)
        }
    }

    func reset() {
        email = ""
        password = ""
        confirmPassword = ""
        result = nil
        isLoading = false
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }
}
