//
//  ConnectedView.swift
//  postura
//
//  Created by YunHao Dong on 12/28/25.
//
import SwiftUI
 
import SwiftUI
 
struct ConnectedView: View {
    @ObservedObject var postura: PosturaManager
    @State private var showCalendar = false
    @State private var showStatistics = false
    @State private var pulseTracking = false
 
    // MARK: - Computed Properties
 
    var postureStatus: (text: String, color: Color, icon: String) {
        switch postura.bleManager.PostureStatus {
        case 1: return ("Great posture!", .green, "checkmark.circle.fill")
        case 2: return ("Poor posture", .red, "xmark.circle.fill")
        default: return ("Waiting for data…", .gray, "hourglass")
        }
    }
 
    var isTodaySelected: Bool {
        Calendar.current.isDateInToday(postura.selectedDate)
    }
 
    var stats: DailyPostureStats {
        postura.stats(for: postura.selectedDate)
    }
 
    var totalTime: TimeInterval { stats.goodTime + stats.badTime }
 
    var goodPercent: Double {
        totalTime > 0 ? stats.goodTime / totalTime : 0
    }
 
    var yesterdayStats: DailyPostureStats { postura.stats(for: date(daysAgo: 1)) }
    var dayBeforeStats: DailyPostureStats { postura.stats(for: date(daysAgo: 2)) }
 
    var improvementSummary: (text: String, color: Color, icon: String)? {
        guard yesterdayStats.goodTime > 0 || dayBeforeStats.goodTime > 0 else { return nil }
        let diff = yesterdayStats.goodTime - dayBeforeStats.goodTime
        if diff > 0 {
            return ("Better than the day before (+\(formatHMS(diff)))", .green, "arrow.up.right.circle.fill")
        } else if diff < 0 {
            return ("Lower than the day before (−\(formatHMS(-diff)))", .red, "arrow.down.right.circle.fill")
        } else {
            return ("Matched the day before", .secondary, "equal.circle.fill")
        }
    }
 
    // MARK: - Body
 
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
 
                    // Status card
                    statusCard
 
                    // Date navigation + stats
                    statsCard
 
                    // Improvement comparison
                    if let summary = improvementSummary {
                        comparisonBanner(summary)
                    }
 
                    // Tracking button
                    if isTodaySelected {
                        trackingButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("postura")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.4), lineWidth: 3)
                                    .scaleEffect(pulseTracking ? 2.2 : 1)
                                    .opacity(pulseTracking ? 0 : 0.6)
                                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulseTracking)
                            )
                        Text("Connected")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .onAppear { pulseTracking = true }
                }
 
                ToolbarItem(placement: .automatic) {
                    Button {
                        showStatistics = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarSheetView(selectedDate: $postura.selectedDate)
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView(postura: postura)
            }
        }
    }
 
    // MARK: - Subviews
 
    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(postureStatus.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: postureStatus.icon)
                    .font(.system(size: 24))
                    .foregroundColor(postureStatus.color)
            }
 
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text(postureStatus.text)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(postureStatus.color)
            }
 
            Spacer()
        }
        .padding(16)
        .cornerRadius(16)
        .animation(.easeInOut(duration: 0.25), value: postura.bleManager.PostureStatus)
    }
 
    private var statsCard: some View {
        VStack(spacing: 0) {
            // Header with date nav
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Summary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                    Text(dateLabel(for: postura.selectedDate))
                        .font(.headline)
                        .fontWeight(.bold)
                }
 
                Spacer()
 
                HStack(spacing: 4) {
                    Button { goToPreviousDay() } label: {
                        Image(systemName: "chevron.left")
                            .padding(8)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
 
                    Button { showCalendar = true } label: {
                        Image(systemName: "calendar")
                            .padding(8)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
 
                    Button { goToNextDay() } label: {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isTodaySelected)
                    .opacity(isTodaySelected ? 0.3 : 1)
                }
                .foregroundColor(.primary)
            }
            .padding(16)
 
            Divider()
                .padding(.horizontal, 16)
 
            // Progress arc + stats
            VStack(spacing: 16) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 12)
                        .frame(width: 110, height: 110)
 
                    Circle()
                        .trim(from: 0, to: CGFloat(goodPercent))
                        .stroke(
                            totalTime > 0
                                ? (goodPercent >= 0.7 ? Color.green : goodPercent >= 0.5 ? Color.orange : Color.red)
                                : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 110, height: 110)
                        .animation(.easeInOut(duration: 0.6), value: goodPercent)
 
                    VStack(spacing: 2) {
                        if totalTime > 0 {
                            Text("\(Int(goodPercent * 100))%")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("good")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("—")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
 
                // Three stat tiles
                HStack(spacing: 12) {
                    StatTile(label: "Good", time: stats.goodTime, color: .green)
                    StatTile(label: "Bad", time: stats.badTime, color: .red)
                    StatTile(label: "Total", time: totalTime, color: .blue)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
        .cornerRadius(16)
    }
 
    private func comparisonBanner(_ summary: (text: String, color: Color, icon: String)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: summary.icon)
                .font(.title3)
            Text(summary.text)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundColor(summary.color)
        .padding(14)
        .background(summary.color.opacity(0.1))
        .cornerRadius(14)
    }
 
    private var trackingButton: some View {
        Button {
            if postura.isTracking {
                postura.stopPostureTracking()
            } else {
                postura.startPostureTracking()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: postura.isTracking ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                Text(postura.isTracking ? "Stop Tracking" : "Start Tracking")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(postura.isTracking ? Color.orange : Color.green)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
 
    // MARK: - Helpers
 
    private func goToPreviousDay() {
        if let prev = Calendar.current.date(byAdding: .day, value: -1, to: postura.selectedDate) {
            postura.selectedDate = prev
        }
    }
 
    private func goToNextDay() {
        if let next = Calendar.current.date(byAdding: .day, value: 1, to: postura.selectedDate) {
            postura.selectedDate = next
        }
    }
}
 
// MARK: - Stat Tile
 
struct StatTile: View {
    let label: String
    let time: TimeInterval
    let color: Color
 
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .textCase(.uppercase)
                .kerning(0.5)
            Text(
                Duration.seconds(time)
                    .formatted(.time(pattern: .hourMinuteSecond))
            )
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}
 
// MARK: - Shared Helpers
 
func formatHMS(_ seconds: TimeInterval) -> String {
    let total = Int(max(0, seconds))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    return h > 0
        ? String(format: "%d:%02d:%02d", h, m, s)
        : String(format: "%02d:%02d", m, s)
}
 
func dateLabel(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) { return "Today" }
    return date.formatted(.dateTime.weekday(.wide).month().day())
}
 
func relativeDayLabel(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) { return "today" }
    if Calendar.current.isDateInYesterday(date) { return "yesterday" }
    return "on " + date.formatted(.dateTime.weekday())
}
 
private func date(daysAgo: Int) -> Date {
    Calendar.current.date(
        byAdding: .day,
        value: -daysAgo,
        to: Calendar.current.startOfDay(for: Date())
    )!
}
 
enum SummaryState {
    case comparison(percent: Int, delta: Int)
    case singleDay(percent: Int)
}
 
struct PostureStatView: View {
    let title: String
    let time: TimeInterval
    let color: Color
 
    var body: some View {
        VStack {
            Text(title).foregroundColor(color)
            Text(Duration.seconds(time).formatted(.time(pattern: .hourMinuteSecond)))
                .font(.title3).fontWeight(.semibold)
        }
    }
}
