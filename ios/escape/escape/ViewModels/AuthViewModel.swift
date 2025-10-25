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
    var isLoading = false
    var result: Result<Void, Error>?

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
                try await authService.signInWithOTP(
                    email: email,
                    redirectTo: URL(
                        string: "io.supabase.user-management://login-callback"
                    )
                )
                result = .success(())
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
        result = nil
        isLoading = false
    }
}
