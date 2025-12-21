//
//  ContentView.swift
//  postura
//
//  Created by YunHao Dong on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var ble = BLEManager()
    
    var body: some View {
        VStack {
            Text("Connect to your Postura Device")
            Button(action: {
                ble.scan()
            }) {
                Text("Scan for Bluetooth Devices")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            // List of peripherals
                List(ble.peripherals, id: \.identifier) { peripheral in
                    Button(action: {
                        ble.connect(to: peripheral)
                        //streamer.peripheral = peripheral
                        peripheral.delegate = ble
                    }) {
                        VStack(alignment: .leading) {
                            Text(peripheral.name ?? "Unknown Device")
                                .font(.headline)
                            Text(peripheral.identifier.uuidString)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Connected device
                if let connected = ble.connectedPeripheral {
                    Text("Connected to: \(connected.name ?? "Unknown")")
                        .padding()
                        .foregroundColor(.green)
                }
                
                Divider()
                
        }
        .padding()
    }
}
