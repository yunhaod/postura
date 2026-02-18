//
//  ConnectedView.swift
//  postura
//
//  Created by YunHao Dong on 12/28/25.
//
import SwiftUI

struct ConnectedView: View {
    @ObservedObject var postura: PosturaManager
    @State private var showCalendar = false
    
    var livePressure: [[Bool]] {
        [
            [postura.bleManager.isPostureGood & 0b000001 == 1, postura.bleManager.isPostureGood & 0b000010 == 2],
            [postura.bleManager.isPostureGood & 0b000100 == 4, postura.bleManager.isPostureGood & 0b001000 == 8],
            [postura.bleManager.isPostureGood & 0b010000 == 16, postura.bleManager.isPostureGood & 0b100000 == 32]
        ]
    }

    var isTodaySelected: Bool {
        Calendar.current.isDateInToday(postura.selectedDate)
    }

    var stats: DailyPostureStats {
        postura.stats(for: postura.selectedDate)
    }
    
    var yesterdayStats: DailyPostureStats {
        postura.stats(for: date(daysAgo: 1))
    }

    var dayBeforeStats: DailyPostureStats {
        postura.stats(for: date(daysAgo: 2))
    }
    
    var goodDifference: TimeInterval {
        yesterdayStats.goodTime - dayBeforeStats.goodTime
    }

    var improvementSummary: (text: String, color: Color, icon: String)? {
        // Only show if both days have data
        guard yesterdayStats.goodTime > 0 || dayBeforeStats.goodTime > 0 else {
            return nil
        }

        if goodDifference > 0 {
            return (
                "Yesterday was better than the day before (+\(formatHMS(goodDifference)))",
                .green,
                "arrow.up.right"
            )
        } else if goodDifference < 0 {
            return (
                "Yesterday was worse than the day before (−\(formatHMS(-goodDifference)))",
                .red,
                "arrow.down.right"
            )
        } else {
            return (
                "Yesterday matched the day before",
                .gray,
                "equal"
            )
        }
    }



    var body: some View {
        VStack(spacing: 24) {
            Text("Connected")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)

            // MARK: - Stats
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Posture Summary")
                            .font(.headline)

                        Text(dateLabel(for: postura.selectedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        // Previous day
                        Button {
                            goToPreviousDay()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCalendar = true
                        } label: {
                            Text(dateLabel(for: postura.selectedDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        // Next day (disable if today)
                        Button {
                            goToNextDay()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTodaySelected)
                        .opacity(isTodaySelected ? 0.4 : 1)
                    }

                }
                .padding(.horizontal)

                Spacer()
                    .frame(height: 24)
                
                Text("Posture Time Today")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    PostureStatView(title: "Good", time: stats.goodTime, color: .green)
                    PostureStatView(title: "Bad", time: stats.badTime, color: .red)
                    PostureStatView(title: "Total", time: stats.goodTime + stats.badTime, color: .blue)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(16)
            
            //MARK: Statistic Summaries
            summaryBanner(for: postura.selectedDate)
            
            PressureCushionView(pressurePoints: livePressure)

            if let summary = improvementSummary {
                VStack{
                    HStack(spacing: 8) {
                        Image(systemName: summary.icon)
                        Text(summary.text)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(summary.color)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(summary.color.opacity(0.1))
                .cornerRadius(12)
            }


            // MARK: - Controls
            if isTodaySelected {
                Button {
                    if postura.bleManager.isTracking {
                        postura.bleManager.writeCommand(4)
                        postura.stopPostureTracking()
                    } else {
                        postura.bleManager.writeCommand(3)
                        postura.startPostureTracking()
                    }
                } label: {
                    Text(postura.bleManager.isTracking ? "Stop Tracking" : "Start Tracking")
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        color: postura.bleManager.isTracking ? .orange : .green
                    )
                )
            }
            
            Spacer()

            Button("Disconnect") {
                if let peripheral = postura.bleManager.connectedPeripheral {
                    postura.bleManager.centralManager.cancelPeripheralConnection(peripheral)
                }
            }
            .foregroundColor(.red)
        }
        .padding()
        .sheet(isPresented: $showCalendar) {
            CalendarSheetView(selectedDate: $postura.selectedDate)
        }
    }
    
    private func goToPreviousDay() {
        if let prev = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: postura.selectedDate
        ) {
            postura.selectedDate = prev
        }
    }

    private func goToNextDay() {
        if let next = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: postura.selectedDate
        ) {
            postura.selectedDate = next
        }
    }
    
    func stats(for date: Date) -> DailyPostureStats {
        postura.stats(for: date)
    }

    func previousDay(of date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: date)!
    }
    
    func summaryState(for date: Date) -> SummaryState? {
        let today = stats(for: date)
        let prev = stats(for: previousDay(of: date))

        let todayTotal = today.goodTime + today.badTime
        let prevTotal = prev.goodTime + prev.badTime

        guard todayTotal > 0 else { return nil }

        let percent = Int((today.goodTime / todayTotal) * 100)

        if prevTotal > 0 {
            let delta = Int(today.goodTime - prev.goodTime)
            return .comparison(percent: percent, delta: delta)
        } else {
            return .singleDay(percent: percent)
        }
    }

    @ViewBuilder
    func summaryBanner(for date: Date) -> some View {
        if let state = summaryState(for: date) {
            
            switch state {

            case .comparison(let percent, let delta):
                let isBetter = delta > 0

                HStack(spacing: 12) {
                    Image(systemName: isBetter ? "arrow.up.right" : "arrow.down.right")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("You've averaged **\(percent)%** good posture on \(relativeDayLabel(for: date)).")

                        Text(
                            isBetter
                            ? "↑ Better than the day before (+\(formatHMS(TimeInterval(delta))))"
                            : "↓ Slightly lower than the day before"
                        )
                    }
                }
                .foregroundColor(isBetter ? .green : .orange)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isBetter ? Color.green : Color.orange).opacity(0.12))
                )

            case .singleDay(let percent):
                let isGoodDay = percent >= 50

                HStack(spacing: 8) {
                    Image(systemName: isGoodDay ? "sparkles" : "exclamationmark.triangle.fill")

                    Text(
                        isGoodDay
                        ? "You've averaged **\(percent)%** good posture \(relativeDayLabel(for: date)). Keep it up!"
                        : "You've averaged **\(percent)%** good posture \(relativeDayLabel(for: date)). Watch your posture."
                    )
                }
                .foregroundColor(isGoodDay ? .blue : .orange)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.12))
                )
            }
        }
    }

}

func relativeDayLabel(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return "Today"
    }
    if Calendar.current.isDateInYesterday(date) {
        return "Yesterday"
    }
    return "on " + date.formatted(.dateTime.weekday())
}


enum SummaryState {
    case comparison(percent: Int, delta: Int)
    case singleDay(percent: Int)
}

struct DayComparison {
    let percentage: Int
    let deltaSeconds: Int
    let isBetter: Bool
}


func formatHMS(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60

    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}

func dateLabel(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return "Today"
    } else {
        return date.formatted(
            .dateTime.weekday(.wide).month().day()
        )
    }
}

struct PostureStatView: View {
    let title: String
    let time: TimeInterval
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .foregroundColor(color)

            Text(
                Duration.seconds(time)
                    .formatted(.time(pattern: .hourMinuteSecond))
            )
            .font(.title3)
            .fontWeight(.semibold)
        }
    }
}


private func date(daysAgo: Int) -> Date {
    Calendar.current.date(
        byAdding: .day,
        value: -daysAgo,
        to: Calendar.current.startOfDay(for: Date())
    )!
}
