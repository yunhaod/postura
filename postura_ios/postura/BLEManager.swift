//
//  BLEManager.swift
//  postura
//
//  Created by YunHao Dong on 12/20/25.
//


import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject,
                  CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isConnected: Bool = false
    @Published var isTracking = false
    @Published var PostureStatus: Int8 = 0
    @Published var peripherals: [CBPeripheral] = []

    var centralManager: CBCentralManager!
    
    var PostureServiceUUID = CBUUID(string : "a3721400-00b0-4240-ba50-05ca45bf8abc")
    var PostureCharacteristicUUID = CBUUID(string: "a3721400-00b0-4240-ba50-05ca45bf8dec")
    var CommandCharacteristicUUID = CBUUID(string: "a3721400-00b0-4240-ba50-05ca45bf8def")
    
    var CommandCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is ON")
        } else {
            print("Bluetooth is NOT available")
        }
    }
    
    func scan() {
        peripherals.removeAll()
        centralManager.scanForPeripherals(withServices : [PostureServiceUUID], options: nil)
        print("Scanning...")
    }
    
    func centralManager(_ central: CBCentralManager,
                            didDiscover peripheral: CBPeripheral,
                            advertisementData: [String : Any],
                            rssi RSSI: NSNumber) {

        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            var updated = self.peripherals
            updated.append(peripheral)
            self.peripherals = updated
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
            centralManager.stopScan()
            connectedPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            print("Connecting to \(peripheral.name ?? "Unknown")...")
            peripheral.delegate = self
        }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        isConnected = true
        peripheral.discoverServices(nil)
    }
 
    func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverCharacteristicsFor service: CBService,
                        error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // Check if the current characteristic's UUID is present in our list
            if characteristic.uuid == PostureCharacteristicUUID {
                // Use the characteristic's UUID string for clear logging
                print("Found target characteristic! UUID: \(characteristic.uuid.uuidString). Subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == CommandCharacteristicUUID {
                CommandCharacteristic = characteristic
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {

        connectedPeripheral = nil
        isConnected = false
        isTracking = false
    }

    
    //MARK: Discovering characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            print("Discovered service: \(service.uuid)")
            // Discover characteristics of the service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // MARK: INCOMING UPDATES
    //Called whenever a characteristic update arrives
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
            let status = data.first else { return }
 
            // determine if the posture data has changed, sending 10 means good
            //other numbers mean something in the cushion isn't fulfilled
            let newStatus = Int8(status)
    guard newStatus != PostureStatus else { return }
        PostureStatus = newStatus
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        connectedPeripheral = nil
        isConnected = false
        isTracking = false
    }
    

    
    func writeCommand(_ value: UInt8) {
        guard let peripheral = connectedPeripheral,
              let characteristic = CommandCharacteristic else { return }

        peripheral.writeValue(
            Data([value]),
            for: characteristic,
            type: .withResponse
        )
    }
    
}

struct DailyPostureStats: Identifiable, Codable {
    var id: Date { date }
    let date: Date
    var goodTime: TimeInterval
    var badTime: TimeInterval
}

func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}


