//
//  AppConfigModel.swift
//  escape
//
//  Created by Claude on 1/11/2025.
//

import Foundation

struct AppConfig: Codable, Identifiable {
    let id: UUID
    let minimumVersion: String
    let isMaintenanceMode: Bool
    let maintenanceMessageEn: String?
    let maintenanceMessageJa: String?
    let forceUpdateMessageEn: String?
    let forceUpdateMessageJa: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case minimumVersion = "minimum_version"
        case isMaintenanceMode = "is_maintenance_mode"
        case maintenanceMessageEn = "maintenance_message_en"
        case maintenanceMessageJa = "maintenance_message_ja"
        case forceUpdateMessageEn = "force_update_message_en"
        case forceUpdateMessageJa = "force_update_message_ja"
        case createdAt = "created_at"
    }

    /// Get the maintenance message for the current locale
    func getMaintenanceMessage(locale: Locale = Locale.current) -> String? {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        return languageCode.starts(with: "ja") ? maintenanceMessageJa : maintenanceMessageEn
    }

    /// Get the force update message for the current locale
    func getForceUpdateMessage(locale: Locale = Locale.current) -> String? {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        return languageCode.starts(with: "ja") ? forceUpdateMessageJa : forceUpdateMessageEn
    }

    /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
    static func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(v1Components.count, v2Components.count)

        for i in 0 ..< maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0

            if v1Value < v2Value {
                return .orderedAscending
            } else if v1Value > v2Value {
                return .orderedDescending
            }
        }

        return .orderedSame
    }

    /// Check if the current app version requires an update
    func requiresUpdate(appVersion: String) -> Bool {
        return AppConfig.compareVersions(appVersion, minimumVersion) == .orderedAscending
    }
}
