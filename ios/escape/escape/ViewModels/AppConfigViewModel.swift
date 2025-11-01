//
//  AppConfigViewModel.swift
//  escape
//
//  Created by Claude on 1/11/2025.
//

import Foundation
import SwiftUI

@Observable
class AppConfigViewModel {
    var appConfig: AppConfig?
    var isCheckingConfig = true
    var configError: Error?

    private let appConfigService = AppConfigSupabase()

    init() {}

    /// Check app configuration on launch
    func checkAppConfig() async {
        do {
            let config = try await appConfigService.getLatestConfig()
            appConfig = config
            isCheckingConfig = false
        } catch {
            print("Failed to fetch app config: \(error)")
            configError = error
            // Continue without config on error
            isCheckingConfig = false
        }
    }

    /// Get the current app version from bundle
    func getCurrentAppVersion() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        return "1.0.0"
    }

    /// Check if maintenance mode is active
    var isMaintenanceMode: Bool {
        appConfig?.isMaintenanceMode ?? false
    }

    /// Check if app needs force update
    var requiresForceUpdate: Bool {
        guard let config = appConfig else { return false }
        return config.requiresUpdate(appVersion: getCurrentAppVersion())
    }

    /// Check if app should show normal flow
    var shouldShowNormalFlow: Bool {
        guard let config = appConfig else { return true }
        return !config.isMaintenanceMode && !config.requiresUpdate(appVersion: getCurrentAppVersion())
    }
}
