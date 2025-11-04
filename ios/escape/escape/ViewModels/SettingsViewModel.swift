//
//  SettingsViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
    var name = ""
    var isLoading = false
    var showLogoutConfirmation = false

    // MARK: - Dependencies

    private let userService: UserSupabase
    private let authService: AuthSupabase

    // MARK: - Initialization

    init(
        userService: UserSupabase = UserSupabase(),
        authService: AuthSupabase = AuthSupabase()
    ) {
        self.userService = userService
        self.authService = authService
    }

    // MARK: - Actions

    func loadProfile() async {
        do {
            let user = try await userService.getCurrentUserProfile()
            name = user.name ?? ""
        } catch {
            debugPrint(error)
        }
    }

    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await userService.updateUserProfile(name: name)
        } catch {
            debugPrint(error)
        }
    }

    func signOut() async throws {
        try await authService.signOut()
    }

    func deleteAccount() async throws {
        try await userService.deleteAccount()
        // Sign out to clear local session after account deletion
        try await authService.signOut()
    }
}
