//
//  StatsView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Charts
import Supabase
import SwiftUI

// MARK: - 統計ビュー

struct StatsView: View {
    @State private var statsController = StatsController()
    @State private var showingStatsDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.title", tableName: "Localizable")
                .font(.headline)

            if statsController.isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                .frame(height: 120)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else if let errorMessage = statsController.errorMessage {
                // Error state
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadRecentMissions()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button(action: {
                    showingStatsDetail = true
                }) {
                    HStack(spacing: 12) {
                        // 左側1/4: 統計要素をアイコンと数値のみで縦に配置
                        VStack(spacing: 16) {
                            IconOnlyStatView(
                                value: "\(statsController.completedMissionsCount)",
                                icon: "checkmark.circle.fill",
                                color: Color("brandMediumBlue")
                            )

                            IconOnlyStatView(
                                value: String(format: "%.1f", statsController.totalDistance) + "km",
                                icon: "figure.walk",
                                color: Color("brandDarkBlue")
                            )

                            IconOnlyStatView(
                                value: "\(statsController.totalSteps)",
                                icon: "figure.walk.circle",
                                color: Color("brandOrange")
                            )
                        }
                        .frame(width: 80)

                        // 右側3/4: チャート表示
                        MissionChartView(missions: statsController.recentMissions)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingStatsDetail) {
            StatsDetailView(missions: statsController.recentMissions)
        }
        .onAppear {
            loadRecentMissions()
        }
    }

    private func loadRecentMissions() {
        Task {
            // Get current user ID from Supabase auth
            guard let currentUser = supabase.auth.currentUser else {
                statsController.errorMessage = "Not authenticated"
                print("⚠️ User not authenticated for stats")
                return
            }

            let userId = currentUser.id
            print("📊 Loading stats for user: \(userId)")

            // Fetch recent missions from Supabase
            await statsController.fetchRecentMissions(userId: userId, limit: 30)
        }
    }
}

// MARK: - アイコンのみ統計ビュー

struct IconOnlyStatView: View {
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - コンパクト統計アイテムビュー

struct CompactStatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - ミッションチャートビュー

struct MissionChartView: View {
    let missions: [Mission]

    var body: some View {
        if missions.isEmpty {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("home.stats.no_data", tableName: "Localizable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(missions, id: \.id) { mission in
                let date = mission.createdAt

                // 歩数の棒グラフ
                BarMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.steps_label", table: "Localizable"), mission.steps ?? 0)
                )
                .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

                // 距離の折れ線グラフ（スケール調整のため1000倍）
                LineMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.distance_label", table: "Localizable"), (mission.distances ?? 0) * 1000)
                )
                .foregroundStyle(Color("brandOrange"))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.distance_label", table: "Localizable"), (mission.distances ?? 0) * 1000)
                )
                .foregroundStyle(Color("brandOrange"))
            }
            .chartXScale(range: .plotDimension(padding: 10))
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                                .foregroundColor(Color("brandMediumBlue"))
                        }
                    }
                }
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(String(format: "%.1f", Double(intValue) / 1000))
                                .font(.caption2)
                                .foregroundColor(Color("brandOrange"))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                }
            }
        }
    }
}

// MARK: - 統計詳細ビュー

enum StatsPeriod: String, CaseIterable {
    case day = "D"
    case week = "W"
    case month = "M"

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }

    var label: String {
        switch self {
        case .day: return String(localized: "stats.period.day", defaultValue: "Day", table: "Localizable")
        case .week: return String(localized: "stats.period.week", defaultValue: "Week", table: "Localizable")
        case .month: return String(localized: "stats.period.month", defaultValue: "Month", table: "Localizable")
        }
    }
}

struct StatsDetailView: View {
    let missions: [Mission]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var detailStatsController = StatsController()
    @State private var userId: UUID?

    // Filter missions based on selected period
    private var filteredMissions: [Mission] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) ?? now

        return missions.filter { mission in
            mission.createdAt >= startDate && mission.createdAt <= now
        }
    }

    // Calculate average steps for filtered missions
    private var averageSteps: Int {
        guard !filteredMissions.isEmpty else { return 0 }
        let total = filteredMissions.compactMap { $0.steps }.reduce(0, +)
        return Int(Double(total) / Double(filteredMissions.count))
    }

    // Calculate average distance for filtered missions
    private var averageDistance: Double {
        guard !filteredMissions.isEmpty else { return 0 }
        let total = filteredMissions.compactMap { $0.distances }.reduce(0, +)
        return total / Double(filteredMissions.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Period Picker and Stats
                    PeriodPickerSection(
                        selectedPeriod: $selectedPeriod,
                        averageSteps: averageSteps,
                        averageDistance: averageDistance,
                        missionCount: filteredMissions.count
                    )

                    // Detail Chart Section
                    DetailChartSection(
                        filteredMissions: filteredMissions,
                        selectedPeriod: selectedPeriod
                    )

                    // Mission History Section
                    MissionHistorySection(filteredMissions: filteredMissions)
                }
                .padding()
            }
            .navigationTitle(String(localized: "home.stats.detail_title", table: "Localizable"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "home.stats.close", table: "Localizable")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Period Picker Section Component

struct PeriodPickerSection: View {
    @Binding var selectedPeriod: StatsPeriod
    let averageSteps: Int
    let averageDistance: Double
    let missionCount: Int

    var body: some View {
        VStack(spacing: 16) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Text(period.label).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Average Stats Display
            VStack(spacing: 8) {
                Text("home.stats.average_steps", tableName: "Localizable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(averageSteps)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color("brandMediumBlue"))

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", averageDistance))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("brandOrange"))
                        Text("home.stats.average_distance", tableName: "Localizable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack(spacing: 4) {
                        Text("\(missionCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("brandDarkBlue"))
                        Text("home.stats.total_missions", tableName: "Localizable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Detail Chart Section Component

struct DetailChartSection: View {
    let filteredMissions: [Mission]
    let selectedPeriod: StatsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.recent_missions", tableName: "Localizable")
                .font(.headline)
                .padding(.horizontal)

            if filteredMissions.isEmpty {
                emptyChartView
            } else {
                missionChart
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("home.stats.no_data", tableName: "Localizable")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    private var missionChart: some View {
        Chart(filteredMissions, id: \.id) { mission in
            let date = mission.createdAt
            let barWidth: CGFloat = selectedPeriod == .day ? 60 : selectedPeriod == .week ? 30 : 15

            BarMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.steps_label", table: "Localizable"), mission.steps ?? 0),
                width: .fixed(barWidth)
            )
            .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

            LineMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.distance_label", table: "Localizable"), (mission.distances ?? 0) * 1000)
            )
            .foregroundStyle(Color("brandOrange"))
            .lineStyle(StrokeStyle(lineWidth: 3))

            PointMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.distance_label", table: "Localizable"), (mission.distances ?? 0) * 1000)
            )
            .foregroundStyle(Color("brandOrange"))
            .symbolSize(50)
        }
        .frame(height: 250)
        .chartXScale(range: .plotDimension(padding: 15))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)" + String(localized: "home.stats.steps_unit", table: "Localizable"))
                            .font(.caption)
                            .foregroundColor(Color("brandMediumBlue"))
                    }
                }
            }
            AxisMarks(position: .trailing) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(String(format: "%.1f", Double(intValue) / 1000) + String(localized: "home.stats.distance_unit", table: "Localizable"))
                            .font(.caption)
                            .foregroundColor(Color("brandOrange"))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(format: selectedPeriod == .month ? .dateTime.month().day() : .dateTime.day())
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Mission History Section Component

struct MissionHistorySection: View {
    let filteredMissions: [Mission]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.mission_history", tableName: "Localizable")
                .font(.headline)
                .padding(.horizontal)

            if filteredMissions.isEmpty {
                emptyHistoryView
            } else {
                missionList
            }
        }
        .padding(.horizontal)
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("home.stats.no_missions", tableName: "Localizable")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var missionList: some View {
        ForEach(filteredMissions) { mission in
            MissionHistoryRow(mission: mission)
        }
    }
}

// MARK: - Mission History Row Component

struct MissionHistoryRow: View {
    let mission: Mission

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(mission.overview ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(mission.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(mission.steps ?? 0)" + String(localized: "home.stats.steps_unit", table: "Localizable"))
                    .font(.caption)
                    .foregroundColor(Color("brandMediumBlue"))

                Text(String(format: "%.1f", mission.distances ?? 0) + String(localized: "home.stats.distance_unit", table: "Localizable"))
                    .font(.caption)
                    .foregroundColor(Color("brandOrange"))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - 統計アイテムビュー（互換性のため保持）

struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
}
