//
//  AppConfigSupabase.swift
//  escape
//
//  Created by Claude on 1/11/2025.
//

import Foundation
import Supabase

class AppConfigSupabase {
    /// Fetches the latest app configuration from the database
    /// - Returns: AppConfig object with the latest configuration
    /// - Throws: Database error if fetch fails
    func getLatestConfig() async throws -> AppConfig {
        let configs: [AppConfig] = try await supabase
            .from("app_config")
            .select()
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let config = configs.first else {
            throw NSError(
                domain: "AppConfigSupabase",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No app configuration found"]
            )
        }

        return config
    }
}
