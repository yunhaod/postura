//
//  ContentView.swift
//  postura
//
//  Created by YunHao Dong on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var posturaManager: PosturaManager

    init() {
        let ble = BLEManager()
        _bleManager = StateObject(wrappedValue: ble)
        _posturaManager = StateObject(
            wrappedValue: PosturaManager(bleManager: ble)
        )
    }

    var body: some View {
        Group {
            if bleManager.isConnected {
                ConnectedView(postura: posturaManager)
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
