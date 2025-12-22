//
//  ContentView.swift
//  postura
//
//  Created by YunHao Dong on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var bleManager = BLEManager()

    var body: some View {
        Group {
            if bleManager.isConnected {
                ConnectedView(ble: bleManager)
            } else {
                ScanView(ble: bleManager)
            }
        }
    }
}


struct ScanView: View {
    @ObservedObject var ble: BLEManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Postura")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scanning for devices")
                .foregroundColor(.secondary)

            Button("Start Scan") {
                ble.scan()
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))

            List(ble.peripherals, id: \.identifier) { peripheral in
                Button {
                    ble.connect(to: peripheral)
                    peripheral.delegate = ble
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(peripheral.name ?? "Unknown Device")
                            .font(.headline)

                        Text(peripheral.identifier.uuidString)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }
}


struct ConnectedView: View {
    @ObservedObject var ble: BLEManager

    var body: some View {
        VStack(spacing: 24) {
            Text("Connected")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)

            // MARK: - Controls
            VStack(spacing: 12) {
                Button("Start Tracking") {
                    ble.writeCommand(3)
                    ble.startPostureTracking()
                }
                .buttonStyle(PrimaryButtonStyle(color: .green))

                Button("Stop Tracking") {
                    ble.writeCommand(4)
                }
                .buttonStyle(PrimaryButtonStyle(color: .orange))
            }

            // MARK: - Stats
            VStack(spacing: 8) {
                Text("Posture Time Today")
                    .font(.headline)

                HStack(spacing: 20) {
                    VStack {
                        Text("Good")
                            .foregroundColor(.green)
                        let good_duration = Duration.seconds(ble.goodPostureTime)
                        Text(good_duration.formatted(.time(pattern: .hourMinuteSecond)))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    VStack {
                        Text("Bad")
                            .foregroundColor(.red)
                        let bad_duration = Duration.seconds(ble.badPostureTime)
                        Text(bad_duration.formatted(.time(pattern: .hourMinuteSecond)))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    VStack {
                        Text("Total")
                            .foregroundColor(.red)
                        let total_duration = Duration.seconds(ble.badPostureTime) + Duration.seconds(ble.goodPostureTime)
                        Text(total_duration.formatted(.time(pattern: .hourMinuteSecond)))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(white: 12))
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
