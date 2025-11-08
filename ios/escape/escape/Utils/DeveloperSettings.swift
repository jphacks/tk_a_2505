//
//  DeveloperSettings.swift
//  escape
//
//  Created by AI Assistant on 8/11/2025.
//

import Foundation

/// Developer settings for configuring app behavior during development
class DeveloperSettings {
    // MARK: - Keys

    private enum Keys {
        static let shelterProximityRadius = "dev_shelter_proximity_radius"
        static let showRadiusArea = "dev_show_radius_area"
    }

    // MARK: - Singleton

    static let shared = DeveloperSettings()

    private init() {}

    // MARK: - Settings

    /// The radius in meters for shelter proximity detection
    /// Default: 10 meters
    var shelterProximityRadius: Double {
        get {
            let value = UserDefaults.standard.double(forKey: Keys.shelterProximityRadius)
            return value > 0 ? value : 10.0 // Default to 10 meters if not set
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.shelterProximityRadius)
        }
    }

    /// Whether to show the radius area around the user on the map
    /// Default: false
    var showRadiusArea: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.showRadiusArea)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.showRadiusArea)
        }
    }

    // MARK: - Helper Methods

    /// Reset all developer settings to their defaults
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: Keys.shelterProximityRadius)
        UserDefaults.standard.removeObject(forKey: Keys.showRadiusArea)
    }

    /// Get all current developer settings as a dictionary for debugging
    func getAllSettings() -> [String: Any] {
        return [
            "shelterProximityRadius": shelterProximityRadius,
            "showRadiusArea": showRadiusArea,
        ]
    }
}
