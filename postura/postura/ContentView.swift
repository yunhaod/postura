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
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
