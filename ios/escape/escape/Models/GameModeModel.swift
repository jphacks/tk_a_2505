//
//  GameModeModel.swift
//  escape
//
//  Created by Claude on 11/4/2025.
//

import Foundation

/// Represents different gameplay modes
enum GameMode: String, Codable, CaseIterable {
    case `default`
    case zen
    case mapless

    /// Localized name of the game mode
    var localizedName: String {
        switch self {
        case .default:
            return String(localized: "game_mode.default.name", table: "Localizable")
        case .zen:
            return String(localized: "game_mode.zen.name", table: "Localizable")
        case .mapless:
            return String(localized: "game_mode.mapless.name", table: "Localizable")
        }
    }

    /// Localized description of the game mode
    var localizedDescription: String {
        switch self {
        case .default:
            return String(localized: "game_mode.default.description", table: "Localizable")
        case .zen:
            return String(localized: "game_mode.zen.description", table: "Localizable")
        case .mapless:
            return String(localized: "game_mode.mapless.description", table: "Localizable")
        }
    }

    /// Whether this mode has zombies
    var hasZombies: Bool {
        switch self {
        case .default, .mapless:
            return true
        case .zen:
            return false
        }
    }

    /// Whether this mode shows the map
    var showsMap: Bool {
        switch self {
        case .default, .zen:
            return true
        case .mapless:
            return false
        }
    }

    /// Whether this mode tracks time/score
    var tracksScore: Bool {
        switch self {
        case .default, .mapless:
            return true
        case .zen:
            return false
        }
    }
}
