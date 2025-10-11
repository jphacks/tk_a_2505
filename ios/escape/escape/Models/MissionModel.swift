//
//  MissionModel.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation

/// Represents the state of today's mission
enum MissionState: String, Codable {
    case noMission = "none"
    case inProgress = "creating"
    case active = "have"
    case completed = "done"
}
