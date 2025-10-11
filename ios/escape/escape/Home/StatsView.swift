//
//  StatsView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Charts
import SwiftUI

// MARK: - 統計ビュー

struct StatsView: View {
    @State private var recentMissions: [Mission] = []
    @State private var showingStatsDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.title", tableName: "Localizable")
                .font(.headline)

            Button(action: {
                showingStatsDetail = true
            }) {
                HStack(spacing: 12) {
                    // 左側1/4: 統計要素をアイコンと数値のみで縦に配置
                    VStack(spacing: 16) {
                        IconOnlyStatView(
                            value: "5",
                            icon: "checkmark.circle.fill",
                            color: Color("brandMediumBlue")
                        )

                        IconOnlyStatView(
                            value: "3.2km",
                            icon: "figure.walk",
                            color: Color("brandDarkBlue")
                        )

                        IconOnlyStatView(
                            value: "2",
                            icon: "star.fill",
                            color: Color("brandOrange")
                        )
                    }
                    .frame(width: 80)

                    // 右側3/4: チャート表示
                    MissionChartView(missions: recentMissions)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingStatsDetail) {
            StatsDetailView(missions: recentMissions)
        }
        .onAppear {
            loadRecentMissions()
        }
    }

    private func loadRecentMissions() {
        // サンプルデータ - 実際にはSupabaseから取得
        recentMissions = [
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "地震避難訓練",
                overview: "震度6強の地震",
                disasterType: .earthquake,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 2500,
                distances: 1.2,
                createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            ),
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "台風避難訓練",
                overview: "大型台風接近",
                disasterType: .stormSurge,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 3200,
                distances: 1.8,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "火災避難訓練",
                overview: "建物火災発生",
                disasterType: .fire,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 1800,
                distances: 0.9,
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "津波避難訓練",
                overview: "津波警報発令",
                disasterType: .tsunami,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 4100,
                distances: 2.1,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "土砂災害避難訓練",
                overview: "土砂災害警戒",
                disasterType: .landslide,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 2800,
                distances: 1.5,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            Mission(
                id: UUID(),
                userId: UUID(),
                title: "洪水避難訓練",
                overview: "河川氾濫危険",
                disasterType: .flood,
                evacuationRegion: "文京区",
                status: .completed,
                steps: 3500,
                distances: 1.9,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
        ]
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
                Text("データなし")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                ForEach(missions, id: \.id) { mission in
                    let date = mission.createdAt

                    // 歩数の棒グラフ
                    BarMark(
                        x: .value("日付", date),
                        y: .value("歩数", mission.steps ?? 0)
                    )
                    .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

                    // 距離の折れ線グラフ（スケール調整のため1000倍）
                    LineMark(
                        x: .value("日付", date),
                        y: .value("距離", (mission.distances ?? 0) * 1000)
                    )
                    .foregroundStyle(Color("brandOrange"))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("日付", date),
                        y: .value("距離", (mission.distances ?? 0) * 1000)
                    )
                    .foregroundStyle(Color("brandOrange"))
                }
            }
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

struct StatsDetailView: View {
    let missions: [Mission]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 詳細チャート
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近のミッション統計")
                            .font(.headline)

                        Chart {
                            ForEach(missions, id: \.id) { mission in
                                let date = mission.createdAt

                                BarMark(
                                    x: .value("日付", date),
                                    y: .value("歩数", mission.steps ?? 0),
                                    width: .fixed(30)
                                )
                                .foregroundStyle(Color("brandMediumBlue").opacity(0.7))

                                LineMark(
                                    x: .value("日付", date),
                                    y: .value("距離", (mission.distances ?? 0) * 1000)
                                )
                                .foregroundStyle(Color("brandOrange"))
                                .lineStyle(StrokeStyle(lineWidth: 3))

                                PointMark(
                                    x: .value("日付", date),
                                    y: .value("距離", (mission.distances ?? 0) * 1000)
                                )
                                .foregroundStyle(Color("brandOrange"))
                                .symbolSize(50)
                            }
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue) 歩")
                                            .font(.caption)
                                            .foregroundColor(Color("brandMediumBlue"))
                                    }
                                }
                            }
                            AxisMarks(position: .trailing) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text(String(format: "%.1fkm", Double(intValue) / 1000))
                                            .font(.caption)
                                            .foregroundColor(Color("brandOrange"))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // ミッション履歴
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ミッション履歴")
                            .font(.headline)

                        ForEach(missions) { mission in
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
                                    Text("\(mission.steps ?? 0) 歩")
                                        .font(.caption)
                                        .foregroundColor(Color("brandMediumBlue"))

                                    Text(String(format: "%.1fkm", mission.distances ?? 0))
                                        .font(.caption)
                                        .foregroundColor(Color("brandOrange"))
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("統計詳細")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
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
