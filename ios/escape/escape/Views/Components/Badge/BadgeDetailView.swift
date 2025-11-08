//
//  BadgeDetailView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import MapKit
import Supabase
import SwiftUI
import UIKit

// MARK: - Map Annotation Model

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Progress Circles View

struct ProgressCirclesView: View {
    let currentRounds: Int
    let targetRounds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar with level indicators
            HStack(spacing: 12) {
                // Current level label
                Text(String(localized: "badge.level", table: "Localizable") + " \(getCurrentLevel())")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // Progress bar: line + dots + line
                HStack(spacing: 8) {
                    // Leading line
                    Rectangle()
                        .fill(Color("brandOrange"))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)

                    // Progress dots
                    HStack(spacing: 6) {
                        let dotsNeeded = getDotsNeededForNextLevel()
                        let currentProgress = getCurrentLevelProgress()

                        ForEach(0 ..< dotsNeeded, id: \.self) { index in
                            Circle()
                                .fill(index < currentProgress ? Color("brandOrange") : Color(.systemGray4))
                                .frame(width: 12, height: 12)
                                .scaleEffect(index < currentProgress ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: currentProgress
                                )
                        }
                    }

                    // Trailing line
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                }

                // Next level label (if not max level)
                if getCurrentLevel() < 5 {
                    Text(String(localized: "badge.level", table: "Localizable") + " \(getCurrentLevel() + 1)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                } else {
                    Text(String(localized: "badge.max_level", table: "Localizable"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("brandOrange"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                let dotsNeeded = getDotsNeededForNextLevel()
                let currentProgress = getCurrentLevelProgress()

                if currentProgress < dotsNeeded {
                    let remaining = dotsNeeded - currentProgress
                    Text(
                        String(
                            format: NSLocalizedString(
                                "badge.visits_needed_to_level_up", tableName: "Localizable", comment: ""
                            ),
                            remaining, remaining == 1 ? "" : "s"
                        )
                    )
                    .font(.caption2)
                    .foregroundColor(Color("brandOrange"))
                    .fontWeight(.medium)
                } else if getCurrentLevel() < 5 {
                    Text(String(localized: "badge.ready_for_next_level", table: "Localizable"))
                        .font(.caption2)
                        .foregroundColor(Color("brandOrange"))
                        .fontWeight(.medium)
                }
            }
        }
    }

    private func getCurrentLevel() -> Int {
        let thresholds = [0, 1, 3, 6, 10, 15]
        for (level, threshold) in thresholds.enumerated() {
            if currentRounds < threshold {
                return max(0, level - 1)
            }
        }
        return 5 // Max level
    }

    private func getDotsNeededForNextLevel() -> Int {
        let thresholds = [0, 1, 3, 6, 10, 15]
        let currentLevel = getCurrentLevel()

        if currentLevel >= 5 {
            return 5 // Show 5 dots for max level
        }

        let currentLevelThreshold = thresholds[currentLevel]
        let nextLevelThreshold = thresholds[currentLevel + 1]

        return nextLevelThreshold - currentLevelThreshold
    }

    private func getCurrentLevelProgress() -> Int {
        let thresholds = [0, 1, 3, 6, 10, 15]
        let currentLevel = getCurrentLevel()

        if currentLevel >= 5 {
            return 5 // Max progress for max level
        }

        let currentLevelThreshold = thresholds[currentLevel]
        return currentRounds - currentLevelThreshold
    }
}

// MARK: - 詳細画面用回転可能バッジビュー

struct RotatableBadgeView: View {
    let badge: Badge
    @State private var isFlipped = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            if !isFlipped {
                // 前面
                DetailBadgeFrontView(badge: badge)
            } else {
                // 背面
                DetailBadgeBackView(badge: badge)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            HapticFeedback.shared.mediumImpact()
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle += 180
                isFlipped.toggle()
            }
        }
        .frame(width: 150, height: 150)
    }
}

// MARK: - バッジ前面ビュー

struct DetailBadgeFrontView: View {
    let badge: Badge

    var body: some View {
        ZStack {
            // 背景の影
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.1),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 5, y: 5)
                .blur(radius: 3)

            // メインの画像表示
            if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
                // Use AsyncImage for remote URLs
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                    case .failure:
                        // Fallback to imageName if URL fails
                        if let imageName = badge.imageName, !imageName.isEmpty {
                            DetailImageLoader(imageName: imageName)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                badge.color.opacity(0.9),
                                                badge.color.opacity(0.7),
                                                badge.color.opacity(0.5),
                                                badge.color.opacity(0.3),
                                            ]),
                                            center: .topLeading,
                                            startRadius: 10,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.8),
                                                        Color.white.opacity(0.3),
                                                        Color.clear,
                                                        Color.black.opacity(0.2),
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                    )

                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                            }
                        }
                    @unknown default:
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            badge.color.opacity(0.9),
                                            badge.color.opacity(0.7),
                                            badge.color.opacity(0.5),
                                            badge.color.opacity(0.3),
                                        ]),
                                        center: .topLeading,
                                        startRadius: 10,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.3),
                                                    Color.clear,
                                                    Color.black.opacity(0.2),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )

                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                        }
                    }
                }
            } else if let imageName = badge.imageName, !imageName.isEmpty {
                // Fallback to local image
                DetailImageLoader(imageName: imageName)
            } else {
                // No image available
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    badge.color.opacity(0.9),
                                    badge.color.opacity(0.7),
                                    badge.color.opacity(0.5),
                                    badge.color.opacity(0.3),
                                ]),
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.2),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )

                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
            }

            // ハイライト効果
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            Color.clear,
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .offset(x: -15, y: -15)
                .opacity(0.7)
        }
    }
}

// MARK: - バッジ背面ビュー

struct DetailBadgeBackView: View {
    let badge: Badge

    var body: some View {
        ZStack {
            // 背景の影
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.1),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 5, y: 5)
                .blur(radius: 3)

            // 背面の暗い円
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.5),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.6),
                                    Color.gray.opacity(0.3),
                                    Color.clear,
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            // 背面の情報表示
            VStack(spacing: 8) {
                if badge.isUnlocked {
                    Text(String(localized: "badge.getter", table: "Localizable"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(badge.firstUserName ?? "Unknown User")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(String(localized: "badge.acquisition_date", table: "Localizable"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)

                    Text(dateFormatter.string(from: Date()))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.5))

                    Text(String(localized: "badge.not_acquired", table: "Localizable"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

// MARK: - 熟練度星アイコンコンポーネント

struct SkillStarsView: View {
    let starCount: Int
    let maxStars: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< maxStars, id: \.self) { index in
                SkillStarView(isFilled: index < starCount)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SkillStarView: View {
    let isFilled: Bool

    var body: some View {
        ZStack {
            // 影
            Image(systemName: "star.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black.opacity(0.25))
                .offset(x: 1.5, y: 2)
                .blur(radius: 1.5)

            // メインの星
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isFilled ? .yellow : .white.opacity(0.3))

            // 立体的なハイライト（埋まった星のみ）
            if isFilled {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: 0.4),
                                .init(color: .clear, location: 0.8),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: -1, y: -1)
                    .blendMode(.overlay)
            }
        }
    }
}

// MARK: - コンパクト熟練度星アイコンコンポーネント

struct CompactSkillStarsView: View {
    let starCount: Int
    let maxStars: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< maxStars, id: \.self) { index in
                CompactSkillStarView(isFilled: index < starCount)
            }
        }
    }
}

struct CompactSkillStarView: View {
    let isFilled: Bool

    var body: some View {
        ZStack {
            // 影
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.25))
                .offset(x: 1, y: 1.5)
                .blur(radius: 1)

            // メインの星
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isFilled ? .yellow : .white.opacity(0.3))

            // 立体的なハイライト（埋まった星のみ）
            if isFilled {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: 0.4),
                                .init(color: .clear, location: 0.8),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: -0.5, y: -0.5)
                    .blendMode(.overlay)
            }
        }
    }
}

// MARK: - 経験値ゲージコンポーネント

struct ExperienceGaugeView: View {
    let currentMissions: Int
    let currentStarLevel: Int

    private var progress: Double {
        let thresholds = [0, 1, 3, 6, 10, 15] // 各星レベルに必要なミッション数

        if currentStarLevel >= 5 {
            return 1.0 // 最大レベル
        }

        let currentThreshold = thresholds[currentStarLevel]
        let nextThreshold = thresholds[currentStarLevel + 1]

        if currentMissions >= nextThreshold {
            return 1.0
        }

        let progressInCurrentLevel = Double(currentMissions - currentThreshold)
        let totalNeededForNextLevel = Double(nextThreshold - currentThreshold)

        return max(0.0, min(1.0, progressInCurrentLevel / totalNeededForNextLevel))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // プログレス
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
        .frame(width: 120)
    }
}

// MARK: - 詳細画面用画像ローダー

struct DetailImageLoader: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
    }
}

// MARK: - バッジ詳細ビュー

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    @State private var randomBackgroundColor = Badge.randomColor
    @State private var averageBackgroundColor: Color? = nil
    @State private var skillLevel: Int = 0
    @State private var missionCount: Int = 0
    @State private var isLoadingSkillLevel = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on badge image average color
                Group {
                    if let averageColor = averageBackgroundColor {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: averageColor.asBackgroundColor(opacity: 0.9), location: 0.0),
                                .init(color: averageColor.asBackgroundColor(opacity: 0.7), location: 0.4),
                                .init(color: Color(.systemGroupedBackground).opacity(0.3), location: 1.0),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .animation(.easeInOut(duration: 0.8), value: averageBackgroundColor)
                    } else {
                        Color(.systemGroupedBackground)
                    }
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダーセクション
                        VStack(spacing: 16) {
                            // 回転可能なバッジ
                            RotatableBadgeView(badge: badge)

                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let badgeNumber = badge.badgeNumber {
                                        Text("#\(badgeNumber)")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }

                                    Text(badge.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Progress indicator
                                if !isLoadingSkillLevel {
                                    VStack(alignment: .leading, spacing: 16) {
                                        // Progress circles
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(String(localized: "badge.your_level", table: "Localizable"))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)

                                            ProgressCirclesView(
                                                currentRounds: missionCount,
                                                targetRounds: getTargetRoundsForCurrentLevel()
                                            )
                                        }
                                        .padding(20)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(20)
                                    }
                                    .padding(.top, 12)
                                } else {
                                    // ローディング表示
                                    HStack(spacing: 12) {
                                        HStack(spacing: 6) {
                                            ProgressView()
                                                .tint(.secondary)
                                            Text("Loading...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .padding(.top, 12)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // 詳細情報セクション
                        VStack(spacing: 20) {
                            // 住所情報
                            if let address = badge.address {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(String(localized: "badge.address", table: "Localizable"))
                                        .font(.headline)
                                        .foregroundColor(.black)

                                    VStack(alignment: .leading, spacing: 4) {
                                        if let municipality = badge.municipality {
                                            Text(municipality)
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(address)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .lineSpacing(4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }

                            // 対応災害情報
                            if !badge.supportedDisasters.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(String(localized: "badge.supported_disasters", table: "Localizable"))
                                        .font(.headline)
                                        .foregroundColor(.black)

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(), alignment: .leading),
                                            GridItem(.flexible(), alignment: .leading),
                                        ], spacing: 12
                                    ) {
                                        ForEach(badge.supportedDisasters, id: \.name) { disaster in
                                            HStack(spacing: 6) {
                                                Image(systemName: disaster.icon)
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                                    .frame(width: 16, height: 16)
                                                Text(disaster.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }

                            // マップ表示
                            if let latitude = badge.latitude, let longitude = badge.longitude {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(String(localized: "badge.location", table: "Localizable"))
                                        .font(.headline)
                                        .foregroundColor(.black)

                                    Map {
                                        Marker(
                                            "",
                                            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                        )
                                        .tint(.red)
                                    }
                                    .mapStyle(.standard)
                                    .frame(height: 200)
                                    .cornerRadius(20)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 24)

                        if !badge.isUnlocked {
                            // アクションボタン
                            VStack(spacing: 16) {
                                Button(action: {
                                    // TODO: バッジ取得処理
                                }) {
                                    HStack {
                                        Image(systemName: "location.circle.fill")
                                            .font(.title2)

                                        Text(String(localized: "badge.find_this_badge", table: "Localizable"))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.accentColor)
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        } else {
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "badge.close", table: "Localizable")) {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                Task {
                    await loadSkillLevel()
                    await extractAverageColor()
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Loads the skill level for the current badge
    private func loadSkillLevel() async {
        do {
            let authService = AuthSupabase()
            let missionResultService = MissionResultSupabase()

            let currentUserId = try await authService.getCurrentUserId()

            guard let badgeUUID = UUID(uuidString: badge.id) else {
                await MainActor.run {
                    skillLevel = 0
                    isLoadingSkillLevel = false
                }
                return
            }

            let shelterBadge: ShelterBadge =
                try await supabase
                    .from("shelter_badges")
                    .select()
                    .eq("id", value: badgeUUID)
                    .single()
                    .execute()
                    .value

            let missionResults = try await missionResultService.getUserShelterMissionResults(
                userId: currentUserId,
                shelterId: shelterBadge.shelterId
            )

            let calculatedSkillLevel = SkillLevelCalculator.calculateStarCount(from: missionResults.count)

            await MainActor.run {
                skillLevel = calculatedSkillLevel
                missionCount = missionResults.count
                isLoadingSkillLevel = false
            }

        } catch {
            await MainActor.run {
                skillLevel = 0
                missionCount = 0
                isLoadingSkillLevel = false
            }
        }
    }

    /// Get mission count for display
    private func getMissionCount() -> Int {
        return missionCount
    }

    /// Calculate visits needed for next level
    private func visitsNeededForNextLevel() -> Int {
        let thresholds = [0, 1, 3, 6, 10, 15] // Missions needed for each level

        if skillLevel >= 5 {
            return 0 // Max level reached
        }

        let nextThreshold = thresholds[skillLevel + 1]
        return max(0, nextThreshold - missionCount)
    }

    /// Calculate rounds needed for next level (alias for visitsNeededForNextLevel)
    private func roundsNeededForNextLevel() -> Int {
        return visitsNeededForNextLevel()
    }

    /// Get target rounds for current level progress
    private func getTargetRoundsForCurrentLevel() -> Int {
        let thresholds = [0, 1, 3, 6, 10, 15] // Missions needed for each level

        if skillLevel >= 5 {
            return thresholds[5] // Max level target
        }

        return thresholds[skillLevel + 1] // Next level target
    }

    /// Extract average color from badge image
    private func extractAverageColor() async {
        // First try to get color from image URL
        if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
            await extractColorFromURL(imageUrl)
        }
        // Fallback to local image if URL fails or doesn't exist
        else if let imageName = badge.imageName, !imageName.isEmpty {
            await extractColorFromLocalImage(imageName)
        }
    }

    /// Extract color from remote URL
    private func extractColorFromURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                print("Failed to create UIImage from data")
                return
            }

            let vibrantColor = image.vibrantAverageColor
            await MainActor.run {
                print("🎨 Extracted vibrant color from URL: \(vibrantColor)")
                self.averageBackgroundColor = vibrantColor
            }
        } catch {
            print("Failed to extract color from URL: \(error)")
            // Try fallback to local image if available
            if let imageName = badge.imageName, !imageName.isEmpty {
                await extractColorFromLocalImage(imageName)
            }
        }
    }

    /// Extract color from local image
    private func extractColorFromLocalImage(_ imageName: String) async {
        guard let image = UIImage(named: imageName) else {
            print("Failed to load local image: \(imageName)")
            return
        }

        let vibrantColor = image.vibrantAverageColor
        await MainActor.run {
            print("🎨 Extracted vibrant color from local image: \(vibrantColor)")
            self.averageBackgroundColor = vibrantColor
        }
    }
}
