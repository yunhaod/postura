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
    
    
    @Published var peripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    
    var centralManager: CBCentralManager!
    
    var PostureServiceUUID = CBUUID(string : "a3721400-00b0-4240-ba50-05ca45bf8abc")
    var PostureCharacteristicUUID = CBUUID(string: "a3721400-00b0-4240-ba50-05ca45bf8dec")
    
    var postureStatus = 1;
    
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
            peripherals.append(peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
            centralManager.stopScan()
            connectedPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            print("Connecting to \(peripheral.name ?? "Unknown")...")
            peripheral.delegate = self
        }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        peripheral.delegate = self
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
                // Subscribe to notifications for the found characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
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
            //discovering all characteristics!!!!!
        }
    }
    
    // Called whenever a characteristic update arrives
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
            let status = data.first else { return }

        postureStatus = Int(status)
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        connectedPeripheral = nil
    }
    
}


