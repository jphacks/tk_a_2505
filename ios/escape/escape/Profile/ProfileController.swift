//
//  ProfileController.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import Supabase
import SwiftUI

@MainActor
@Observable
class ProfileController {
    var name = ""
    var isLoading = false

    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user

            let user: User =
                try await supabase
                    .from("users")
                    .select()
                    .eq("id", value: currentUser.id)
                    .single()
                    .execute()
                    .value

            name = user.name ?? ""

        } catch {
            debugPrint(error)
        }
    }

    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let currentUser = try await supabase.auth.session.user

            try await supabase
                .from("users")
                .update(["name": name])
                .eq("id", value: currentUser.id)
                .execute()
        } catch {
            debugPrint(error)
        }
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}
