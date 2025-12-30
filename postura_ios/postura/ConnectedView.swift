//
//  ConnectedView.swift
//  postura
//
//  Created by YunHao Dong on 12/28/25.
//
import SwiftUI

struct ConnectedView: View {
    @ObservedObject var ble: BLEManager
    @State private var showCalendar = false

    var isTodaySelected: Bool {
        Calendar.current.isDateInToday(ble.selectedDate)
    }

    var stats: DailyPostureStats {
        ble.stats(for: ble.selectedDate)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Connected")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)

            // MARK: - Controls
            if isTodaySelected {
                Button {
                    if ble.isTracking {
                        ble.writeCommand(4)
                        ble.stopPostureTracking()
                    } else {
                        ble.writeCommand(3)
                        ble.startPostureTracking()
                    }
                } label: {
                    Text(ble.isTracking ? "Stop Tracking" : "Start Tracking")
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        color: ble.isTracking ? .orange : .green
                    )
                )
            }

            // MARK: - Stats
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Posture Summary")
                            .font(.headline)

                        Text(dateLabel(for: ble.selectedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        showCalendar = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(dateLabel(for: ble.selectedDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

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

            Spacer()

            Button("Disconnect") {
                if let peripheral = ble.connectedPeripheral {
                    ble.centralManager.cancelPeripheralConnection(peripheral)
                }
            }
            .foregroundColor(.red)
        }
        .padding()
        .sheet(isPresented: $showCalendar) {
            CalendarSheetView(selectedDate: $ble.selectedDate)
        }
    }
}



struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
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
