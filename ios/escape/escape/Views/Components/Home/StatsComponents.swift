//
//  StatsComponents.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Charts
import Supabase
import SwiftUI

// MARK: - 統計ビュー

struct StatsView: View {
    @State private var statsViewModel = StatsViewModel()
    @State private var showingStatsDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.title", tableName: "Localizable")
                .font(.headline)

            if statsViewModel.isLoading {
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
            } else if let errorMessage = statsViewModel.errorMessage {
                // Error state
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button(String(localized: "common.retry", table: "Localizable")) {
                        loadRecentMissions()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button(action: {
                    HapticFeedback.shared.lightImpact()
                    showingStatsDetail = true
                }) {
                    HStack(spacing: 12) {
                        // 左側1/4: 統計要素をアイコンと数値のみで縦に配置
                        VStack(spacing: 16) {
                            IconOnlyStatView(
                                value: "\(statsViewModel.completedMissionsCount)",
                                icon: "checkmark.circle.fill",
                                color: Color("brandMediumBlue")
                            )

                            IconOnlyStatView(
                                value: String(format: "%.1f", statsViewModel.totalDistance) + "km",
                                icon: "figure.walk",
                                color: Color("brandDarkBlue")
                            )

                            IconOnlyStatView(
                                value: "\(statsViewModel.totalSteps)",
                                icon: "figure.walk.circle",
                                color: Color("brandOrange")
                            )
                        }
                        .frame(width: 80)

                        // 右側3/4: チャート表示
                        MissionChartView(missionResults: statsViewModel.recentMissionResults)
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
            StatsDetailView(missionResults: statsViewModel.recentMissionResults)
        }
        .onChange(of: showingStatsDetail) { oldValue, newValue in
            // Haptic feedback when sheet is dismissed
            if oldValue && !newValue {
                HapticFeedback.shared.lightImpact()
            }
        }
        .onAppear {
            loadRecentMissions()
        }
    }

    private func loadRecentMissions() {
        Task {
            // Get current user ID from Supabase auth
            guard let currentUser = supabase.auth.currentUser else {
                statsViewModel.errorMessage = "Not authenticated"
                print("⚠️ User not authenticated for stats")
                return
            }

            let userId = currentUser.id
            print("📊 Loading stats for user: \(userId)")

            // Fetch recent missions from Supabase
            await statsViewModel.fetchRecentMissions(userId: userId, limit: 30)
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
    let missionResults: [MissionResult]

    var body: some View {
        if missionResults.isEmpty {
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
            Chart(missionResults) { result in
                let date = result.createdAt

                // 歩数の棒グラフ
                BarMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.steps_label", table: "Localizable"), result.steps ?? 0)
                )
                .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

                // 距離の折れ線グラフ（actualDistanceMeters is already in meters）
                LineMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.distance_label", table: "Localizable"), result.actualDistanceMeters ?? 0)
                )
                .foregroundStyle(Color("brandOrange"))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                    y: .value(String(localized: "chart.distance_label", table: "Localizable"), result.actualDistanceMeters ?? 0)
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
    let missionResults: [MissionResult]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var detailStatsViewModel = StatsViewModel()
    @State private var userId: UUID?

    // Filter mission results based on selected period
    private var filteredMissionResults: [MissionResult] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) ?? now

        return missionResults.filter { result in
            result.createdAt >= startDate && result.createdAt <= now
        }
    }

    // Calculate average steps for filtered mission results
    private var averageSteps: Int {
        guard !filteredMissionResults.isEmpty else { return 0 }
        let total = filteredMissionResults.compactMap { $0.steps }.reduce(0, +)
        return Int(Double(total) / Double(filteredMissionResults.count))
    }

    // Calculate average distance for filtered mission results (in km)
    private var averageDistance: Double {
        guard !filteredMissionResults.isEmpty else { return 0 }
        let total = filteredMissionResults.compactMap { $0.actualDistanceMeters }.reduce(0, +)
        return (total / Double(filteredMissionResults.count)) / 1000.0 // Convert to km
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
                        missionCount: filteredMissionResults.count
                    )

                    // Detail Chart Section
                    DetailChartSection(
                        filteredMissionResults: filteredMissionResults,
                        selectedPeriod: selectedPeriod
                    )

                    // Mission History Section
                    MissionHistorySection(filteredMissionResults: filteredMissionResults)
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
    let filteredMissionResults: [MissionResult]
    let selectedPeriod: StatsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.recent_missions", tableName: "Localizable")
                .font(.headline)
                .padding(.horizontal)

            if filteredMissionResults.isEmpty {
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
        Chart(filteredMissionResults, id: \.id) { result in
            let date = result.createdAt
            let barWidth: CGFloat = selectedPeriod == .day ? 60 : selectedPeriod == .week ? 30 : 15

            BarMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.steps_label", table: "Localizable"), result.steps ?? 0),
                width: .fixed(barWidth)
            )
            .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

            LineMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.distance_label", table: "Localizable"), result.actualDistanceMeters ?? 0)
            )
            .foregroundStyle(Color("brandOrange"))
            .lineStyle(StrokeStyle(lineWidth: 3))

            PointMark(
                x: .value(String(localized: "chart.date_label", table: "Localizable"), date),
                y: .value(String(localized: "chart.distance_label", table: "Localizable"), result.actualDistanceMeters ?? 0)
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
    let filteredMissionResults: [MissionResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.mission_history", tableName: "Localizable")
                .font(.headline)
                .padding(.horizontal)

            if filteredMissionResults.isEmpty {
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
        ForEach(filteredMissionResults) { result in
            MissionHistoryRow(missionResult: result)
        }
    }
}

// MARK: - Mission History Row Component

struct MissionHistoryRow: View {
    let missionResult: MissionResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("home.stats.mission_completed", tableName: "Localizable")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let points = missionResult.finalPoints {
                    Text("\(points) points")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }

                Text(missionResult.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(missionResult.steps ?? 0)" + String(localized: "home.stats.steps_unit", table: "Localizable"))
                    .font(.caption)
                    .foregroundColor(Color("brandMediumBlue"))

                Text(String(format: "%.1f", (missionResult.actualDistanceMeters ?? 0) / 1000) + String(localized: "home.stats.distance_unit", table: "Localizable"))
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
