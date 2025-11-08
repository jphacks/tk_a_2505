//
//  ActivityHeatmapView.swift
//  escape
//
//  Created by Claude on 2025-11-08.
//

import SwiftUI

/// A GitHub-style activity heatmap showing daily points over the past 30 days
struct ActivityHeatmapView: View {
    /// Dictionary mapping date strings (yyyy-MM-dd) to total points
    let dailyPoints: [String: Int]
    /// Base orange color for the heatmap
    private let baseColor = Color(hex: "f54900")

    @State private var selectedDate: String?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var showTooltip = false

    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 7)
    private let cellSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity in the last 30 days")
                .font(.headline)
                .foregroundColor(.primary)

            ZStack(alignment: .topLeading) {
                // Heatmap grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(getLast30Days(), id: \.self) { date in
                        dayCellView(for: date)
                    }
                }

                // Tooltip overlay
                if showTooltip, let selectedDate = selectedDate {
                    tooltipView(for: selectedDate)
                        .position(tooltipPosition)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }

            // Color legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(getColor(for: index, max: 4))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Day Cell View

    private func dayCellView(for date: Date) -> some View {
        let dateString = formatDate(date)
        let points = dailyPoints[dateString] ?? 0
        let color = getColorForPoints(points)

        return Rectangle()
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .onTapGesture { location in
                handleDayTap(date: dateString, points: points, at: location)
            }
    }

    // MARK: - Tooltip View

    private func tooltipView(for dateString: String) -> some View {
        let points = dailyPoints[dateString] ?? 0
        let displayDate = formatDateForDisplay(dateString)

        return VStack(alignment: .leading, spacing: 4) {
            Text(displayDate)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(points) points")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func handleDayTap(date: String, points: Int, at location: CGPoint) {
        selectedDate = date
        // Calculate tooltip position (above the cell)
        tooltipPosition = CGPoint(x: location.x, y: location.y - 50)
        showTooltip = true

        // Auto-hide tooltip after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showTooltip = false
            }
        }
    }

    private func getLast30Days() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<30).reversed().compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }

    private func getColorForPoints(_ points: Int) -> Color {
        if points == 0 {
            return Color(.systemGray6)
        }

        let maxPoints = dailyPoints.values.max() ?? 1
        let intensity = Double(points) / Double(maxPoints)

        return baseColor.opacity(0.3 + (intensity * 0.7))
    }

    private func getColor(for index: Int, max: Int) -> Color {
        if index == 0 {
            return Color(.systemGray6)
        }
        let intensity = Double(index) / Double(max)
        return baseColor.opacity(0.3 + (intensity * 0.7))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateForDisplay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let sampleData: [String: Int] = [
        "2025-10-09": 120,
        "2025-10-10": 80,
        "2025-10-11": 200,
        "2025-10-12": 150,
        "2025-10-15": 90,
        "2025-10-20": 180,
        "2025-10-25": 100,
        "2025-11-01": 220,
        "2025-11-05": 160,
        "2025-11-08": 190
    ]

    return ActivityHeatmapView(dailyPoints: sampleData)
        .padding()
}
