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

