//
//  ProfileViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class ProfileViewModel {
    var name = ""
    var isLoading = false

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

    func getInitialProfile() async {
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
}
