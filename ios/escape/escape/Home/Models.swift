//
//  Models.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - Mission Models

struct Mission: Identifiable {
    let id: String
    let title: String
    let name: String
    let description: String
    let disasterType: DisasterType
    let estimatedDuration: Int
    let distance: Int
    let severity: SeverityLevel
    let isUrgent: Bool
    let aiGeneratedAt: Date
}

enum DisasterType: String, CaseIterable {
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
        case .earthquake: return .orange
        case .flood: return .blue
        case .fire: return .red
        case .typhoon: return .purple
        case .tsunami: return .cyan
        case .landslide: return .brown
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .earthquake: return [.orange, .red]
        case .flood: return [.blue, .cyan]
        case .fire: return [.red, .orange, .yellow]
        case .typhoon: return [.purple, .blue]
        case .tsunami: return [.cyan, .blue]
        case .landslide: return [.brown, .orange]
        }
    }

    var localizedName: String {
        switch self {
        case .earthquake: return "地震"
        case .flood: return "洪水"
        case .fire: return "火災"
        case .typhoon: return "台風"
        case .tsunami: return "津波"
        case .landslide: return "土砂崩れ"
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
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "緊急"
        }
    }

    var pulseAnimation: Bool {
        return self == .critical || self == .high
    }
}

// MARK: - Badge Models

struct Badge: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}
