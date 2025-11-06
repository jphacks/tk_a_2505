//
//  BadgeDetailView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import MapKit
import Supabase
import SwiftUI

// MARK: - Map Annotation Model

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
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
    @State private var isAnimating = false
    @State private var randomBackgroundColor = Badge.randomColor
    @State private var skillLevel: Int = 0
    @State private var isLoadingSkillLevel = true

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [randomBackgroundColor, randomBackgroundColor.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダーセクション
                        VStack(spacing: 16) {
                            // 回転可能なバッジ
                            RotatableBadgeView(badge: badge)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

                            // 熟練度星アイコン
                            if !isLoadingSkillLevel {
                                SkillStarsView(starCount: skillLevel)
                            } else {
                                // ローディング表示
                                HStack(spacing: 8) {
                                    ForEach(0 ..< 5) { _ in
                                        Image(systemName: "star")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                                .padding(.vertical, 8)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                if let badgeNumber = badge.badgeNumber {
                                    Text("Badge No. \(badgeNumber)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(12)
                                }

                                Text(badge.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
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
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 4) {
                                        if let municipality = badge.municipality {
                                            Text(municipality)
                                                .font(.body)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Text(address)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineSpacing(4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                            }

                            // 対応災害情報
                            if !badge.supportedDisasters.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(String(localized: "badge.supported_disasters", table: "Localizable"))
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), alignment: .leading),
                                        GridItem(.flexible(), alignment: .leading),
                                    ], spacing: 12) {
                                        ForEach(badge.supportedDisasters, id: \.name) { disaster in
                                            HStack(spacing: 6) {
                                                Image(systemName: disaster.icon)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .frame(width: 16, height: 16)
                                                Text(disaster.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.25))
                                            .cornerRadius(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                            }

                            // マップ表示
                            if let latitude = badge.latitude, let longitude = badge.longitude {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(String(localized: "badge.location", table: "Localizable"))
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )), annotationItems: [MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { annotation in
                                        MapPin(coordinate: annotation.coordinate, tint: .red)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .disabled(true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
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
                                    .foregroundColor(randomBackgroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
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
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isAnimating = true
                Task {
                    await loadSkillLevel()
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

            let shelterBadge: ShelterBadge = try await supabase
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
                isLoadingSkillLevel = false
            }

        } catch {
            await MainActor.run {
                skillLevel = 0
                isLoadingSkillLevel = false
            }
        }
    }
}
