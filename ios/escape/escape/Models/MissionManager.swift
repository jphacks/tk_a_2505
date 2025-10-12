//
//  MissionManager.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation
import SwiftUI

/// Global state manager for mission-related data
/// Use via @Environment(\.missionStateManager) in SwiftUI views
@Observable
class MissionStateManager {
    /// Current state of today's mission
    var currentMissionState: MissionState = .noMission

    /// Mission data (to be expanded in the future)
    var missionData: String?

    /// Current active mission
    var currentMission: Mission?

    /// Singleton instance for non-SwiftUI contexts
    static let shared = MissionStateManager()

    init() {}

    // MARK: - Mission State Management

    /// Updates the current mission state
    func updateMissionState(_ newState: MissionState) {
        currentMissionState = newState
    }

    /// Updates the current mission
    func updateCurrentMission(_ mission: Mission?) {
        currentMission = mission
        if let mission = mission {
            currentMissionState = mission.status
        } else {
            currentMissionState = .noMission
        }
    }

    /// Resets mission state to default
    func resetMission() {
        currentMissionState = .noMission
        missionData = nil
        currentMission = nil
    }

    // MARK: - Future Mission Data Methods

    // Add mission-specific methods here as needed
}

// MARK: - Environment Key

private struct MissionStateManagerKey: EnvironmentKey {
    static let defaultValue = MissionStateManager.shared
}

extension EnvironmentValues {
    var missionStateManager: MissionStateManager {
        get { self[MissionStateManagerKey.self] }
        set { self[MissionStateManagerKey.self] = newValue }
    }
}
