//
//  StatisticsView.swift
//  postura
//
//  Multi-day posture analytics
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var postura: PosturaManager
    @Environment(\.dismiss) private var dismiss

    // How many days to show — default 7
    @State private var selectedRange: Int = 7

    private let ranges = [7, 14, 30]

    // MARK: - Data

    /// Returns (date, goodPercent, goodTime, badTime) for each day in range
    var dailyData: [(date: Date, percent: Double, goodTime: TimeInterval, badTime: TimeInterval)] {
        (0..<selectedRange).reversed().compactMap { daysAgo -> (Date, Double, TimeInterval, TimeInterval)? in
            guard let d = Calendar.current.date(
                byAdding: .day,
                value: -daysAgo,
                to: Calendar.current.startOfDay(for: Date())
            ) else { return nil }
            let s = postura.stats(for: d)
            let total = s.goodTime + s.badTime
            let pct = total > 0 ? s.goodTime / total : 0
            return (d, pct, s.goodTime, s.badTime)
        }
    }

    var activeDays: [(date: Date, percent: Double, goodTime: TimeInterval, badTime: TimeInterval)] {
        dailyData.filter { $0.goodTime + $0.badTime > 0 }
    }

    var averageGoodPercent: Double {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.percent).reduce(0, +) / Double(activeDays.count)
    }

    var totalGoodTime: TimeInterval {
        activeDays.map(\.goodTime).reduce(0, +)
    }

    var bestDay: (date: Date, percent: Double)? {
        activeDays.max(by: { $0.percent < $1.percent }).map { ($0.date, $0.percent) }
    }

    var streak: Int {
        // Count consecutive days (ending today) with >0 tracked time AND ≥50% good
        var count = 0
        for daysAgo in 0..<selectedRange {
            guard let d = Calendar.current.date(
                byAdding: .day, value: -daysAgo,
                to: Calendar.current.startOfDay(for: Date())
            ) else { break }
            let s = postura.stats(for: d)
            let total = s.goodTime + s.badTime
            guard total > 0, (s.goodTime / total) >= 0.5 else { break }
            count += 1
        }
        return count
    }

    var trend: Double {
        // Slope of good% over days (simple linear)
        guard activeDays.count >= 2 else { return 0 }
        let n = Double(activeDays.count)
        let xs = activeDays.indices.map { Double($0) }
        let ys = activeDays.map(\.percent)
        let xMean = xs.reduce(0, +) / n
        let yMean = ys.reduce(0, +) / n
        let num = zip(xs, ys).map { ($0 - xMean) * ($1 - yMean) }.reduce(0, +)
        let den = xs.map { pow($0 - xMean, 2) }.reduce(0, +)
        return den == 0 ? 0 : num / den
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Range picker
                    rangePicker

                    // Summary tiles
                    summaryTiles

                    // Bar chart
                    chartCard

                    // Day-by-day breakdown
                    breakdownCard
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Statistics")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Range Picker

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedRange = range }
                } label: {
                    Text("\(range)d")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedRange == range ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedRange == range ? .white : .secondary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .cornerRadius(12)
    }

    // MARK: - Summary Tiles

    private var summaryTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

            SummaryTile(
                icon: "percent",
                label: "Avg Good Posture",
                value: activeDays.isEmpty ? "—" : "\(Int(averageGoodPercent * 100))%",
                color: colorForPercent(averageGoodPercent),
                subtitle: trendLabel
            )

            SummaryTile(
                icon: "flame.fill",
                label: "Good Posture Streak",
                value: streak > 0 ? "\(streak)d" : "—",
                color: streak >= 3 ? .orange : .secondary,
                subtitle: streak > 0 ? "days ≥50% good" : "No streak yet"
            )

            SummaryTile(
                icon: "clock.fill",
                label: "Total Good Time",
                value: activeDays.isEmpty ? "—" : formatHoursMinutes(totalGoodTime),
                color: .green,
                subtitle: "across \(activeDays.count) active days"
            )

            SummaryTile(
                icon: "star.fill",
                label: "Best Day",
                value: bestDay.map { "\(Int($0.percent * 100))%" } ?? "—",
                color: .yellow,
                subtitle: bestDay.map { shortDate($0.date) } ?? "No data yet"
            )
        }
    }

    private var trendLabel: String {
        guard activeDays.count >= 2 else { return "Not enough data" }
        if trend > 0.005 { return "↑ Trending upward" }
        if trend < -0.005 { return "↓ Trending downward" }
        return "→ Holding steady"
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Good Posture %")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if activeDays.isEmpty {
                Text("No data for this period.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .multilineTextAlignment(.center)
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(dailyData, id: \.date) { day in
                            let pct = day.goodTime + day.badTime > 0 ? day.percent * 100 : 0
                            BarMark(
                                x: .value("Day", shortDate(day.date)),
                                y: .value("Good %", pct)
                            )
                            .foregroundStyle(
                                (day.goodTime + day.badTime) > 0
                                    ? colorForPercent(day.percent).gradient
                                    : Color.gray.opacity(0.2).gradient
                            )
                            .cornerRadius(4)
                        }

                        RuleMark(y: .value("50%", 50))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                            .annotation(position: .trailing) {
                                Text("50%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisGridLine()
                            if let intVal = value.as(Int.self) {
                                AxisValueLabel("\(intVal)%")
                            }
                        }
                    }
                    .frame(height: 180)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                } else {
                    // iOS 15 fallback: simple bar view
                    simpleBars
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .cornerRadius(16)
    }

    // iOS 15 simple bars fallback
    private var simpleBars: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(dailyData, id: \.date) { day in
                let total = day.goodTime + day.badTime
                let pct = total > 0 ? day.percent : 0
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForPercent(day.percent).opacity(total > 0 ? 1 : 0.15))
                        .frame(maxWidth: .infinity, minHeight: 4)
                        .frame(height: max(4, CGFloat(pct) * 140))
                    Text(tinyDate(day.date))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 180, alignment: .bottom)
    }

    // MARK: - Breakdown Card

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily Breakdown")
                .font(.headline)
                .padding(16)

            Divider()

            if activeDays.isEmpty {
                Text("No tracked data in this period.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                ForEach(dailyData.reversed(), id: \.date) { day in
                    let total = day.goodTime + day.badTime
                    if total > 0 {
                        DayRow(
                            date: day.date,
                            goodPercent: day.percent,
                            goodTime: day.goodTime,
                            badTime: day.badTime
                        )
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .cornerRadius(16)
    }

    // MARK: - Helpers

    func colorForPercent(_ p: Double) -> Color {
        if p >= 0.7 { return .green }
        if p >= 0.5 { return .orange }
        return .red
    }

    func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    func tinyDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        return date.formatted(.dateTime.day())
    }

    func formatHoursMinutes(_ s: TimeInterval) -> String {
        let total = Int(max(0, s))
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Summary Tile

struct SummaryTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Day Row

struct DayRow: View {
    let date: Date
    let goodPercent: Double
    let goodTime: TimeInterval
    let badTime: TimeInterval

    var total: TimeInterval { goodTime + badTime }
    var pct: Int { Int(goodPercent * 100) }

    var barColor: Color {
        if goodPercent >= 0.7 { return .green }
        if goodPercent >= 0.5 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(Calendar.current.isDateInToday(date) ? "Today" :
                         Calendar.current.isDateInYesterday(date) ? "Yesterday" :
                         date.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(pct)% good")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(barColor)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor)
                            .frame(width: geo.size.width * CGFloat(goodPercent), height: 6)
                    }
                }
                .frame(height: 6)

                HStack(spacing: 12) {
                    Label(Duration.seconds(goodTime).formatted(.time(pattern: .hourMinuteSecond)), systemImage: "checkmark")
                        .foregroundColor(.green)
                    Label(Duration.seconds(badTime).formatted(.time(pattern: .hourMinuteSecond)), systemImage: "xmark")
                        .foregroundColor(.red)
                }
                .font(.caption2)
                .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
