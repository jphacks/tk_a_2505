//
//  Model.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - Mission Model

struct Mission: Identifiable {
    let id: String
    let title: String
    let name: String
    let description: String
    let disasterType: DisasterType2
    let estimatedDuration: Int
    let distance: Int
    let severity: SeverityLevel
    let isUrgent: Bool
    let aiGeneratedAt: Date
}

enum DisasterType2: String, CaseIterable {
    case earthquake
    case flood
    case fire
    case typhoon
    case tsunami
    case landslide

    var icon: String {
        switch self {
        case .earthquake: return "exclamationmark.triangle.fill"
        case .flood: return "cloud.rain.fill"
        case .fire: return "flame.fill"
        case .typhoon: return "tornado"
        case .tsunami: return "water.waves"
        case .landslide: return "mountain.2.fill"
        }
    }

    var emergencyIcon: String {
        switch self {
        case .earthquake: return "house.and.flag.fill"
        case .flood: return "drop.fill"
        case .fire: return "flame.circle.fill"
        case .typhoon: return "wind"
        case .tsunami: return "water.waves.and.arrow.up"
        case .landslide: return "arrow.down.to.line"
        }
    }

    var color: Color {
        switch self {
        case .earthquake: return Color("brandOrange")
        case .flood: return Color("brandDarkBlue")
        case .fire: return Color("brandRed")
        case .typhoon: return Color("brandMediumBlue")
        case .tsunami: return Color("brandDarkBlue")
        case .landslide: return Color("brandPeach")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .earthquake: return [Color("brandOrange"), Color("brandRed")]
        case .flood: return [Color("brandDarkBlue"), Color("brandMediumBlue")]
        case .fire: return [Color("brandRed"), Color("brandOrange")]
        case .typhoon: return [Color("brandMediumBlue"), Color("brandDarkBlue")]
        case .tsunami: return [Color("brandDarkBlue"), Color("brandMediumBlue")]
        case .landslide: return [Color("brandPeach"), Color("brandOrange")]
        }
    }

    var localizedName: String {
        switch self {
        case .earthquake: return String(localized: "home.disaster.earthquake", table: "Localizable")
        case .flood: return String(localized: "home.disaster.flood", table: "Localizable")
        case .fire: return String(localized: "home.disaster.fire", table: "Localizable")
        case .typhoon: return String(localized: "home.disaster.typhoon", table: "Localizable")
        case .tsunami: return String(localized: "home.disaster.tsunami", table: "Localizable")
        case .landslide: return String(localized: "home.disaster.landslide", table: "Localizable")
        }
    }
}

enum SeverityLevel: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    var localizedName: String {
        switch self {
        case .low: return String(localized: "home.severity.low", table: "Localizable")
        case .medium: return String(localized: "home.severity.medium", table: "Localizable")
        case .high: return String(localized: "home.severity.high", table: "Localizable")
        case .critical: return String(localized: "home.severity.critical", table: "Localizable")
        }
    }

    var pulseAnimation: Bool {
        return self == .critical || self == .high
    }
}

// MARK: - Badge Model

struct Badge: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}
