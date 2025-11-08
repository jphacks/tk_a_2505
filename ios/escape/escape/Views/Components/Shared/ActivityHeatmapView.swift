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
    @State private var showTooltip = false
    @State private var tooltipFrame: CGRect = .zero

    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 7)
    private let cellSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity in the last 30 days")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                // Weekday labels
                weekdayLabels

                // Heatmap grid with tooltip overlay
                ZStack(alignment: .topLeading) {
                    LazyVGrid(columns: columns, spacing: 4, pinnedViews: []) {
                        ForEach(Array(getAlignedDays().enumerated()), id: \.offset) { index, dayData in
                            if let date = dayData {
                                dayCellView(for: date, index: index)
                            } else {
                                // Empty placeholder cell for alignment
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }

                    // Tooltip overlay
                    if showTooltip, let selectedDate = selectedDate {
                        tooltipView(for: selectedDate)
                            .offset(x: tooltipFrame.minX - 40, y: tooltipFrame.minY - 70)
                            .transition(.opacity)
                            .zIndex(100)
                    }
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

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: cellSize)
            }
        }
    }

    // MARK: - Day Cell View

    private func dayCellView(for date: Date, index: Int) -> some View {
        let dateString = formatDate(date)
        let points = dailyPoints[dateString] ?? 0
        let color = getColorForPoints(points)

        return GeometryReader { geometry in
            Rectangle()
                .fill(color)
                .frame(width: cellSize, height: cellSize)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture {
                    handleDayTap(date: dateString, points: points, frame: geometry.frame(in: .local))
                }
        }
        .frame(width: cellSize, height: cellSize)
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
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func handleDayTap(date: String, points: Int, frame: CGRect) {
        selectedDate = date
        tooltipFrame = frame

        withAnimation(.easeInOut(duration: 0.2)) {
            showTooltip = true
        }

        // Auto-hide tooltip after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTooltip = false
            }
        }
    }

    /// Returns an array of dates aligned to weekdays, with nil for padding
    private func getAlignedDays() -> [Date?] {
        let calendar = Calendar.current
        let dates = getLast30Days()

        guard let firstDate = dates.first else {
            return []
        }

        // Get the weekday of the first date (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: firstDate)

        // Convert to Monday-based index (0 = Monday, 6 = Sunday)
        let mondayBasedIndex = weekday == 1 ? 6 : weekday - 2

        // Create padding with nil values
        var alignedDays: [Date?] = Array(repeating: nil, count: mondayBasedIndex)

        // Add actual dates
        alignedDays.append(contentsOf: dates.map { $0 as Date? })

        return alignedDays
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
