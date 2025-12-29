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
    @Published var isConnected: Bool = false
    @Published var isTracking = false
    @Published var isPostureGood: Bool = false

    @Published var dailyStats: [Date: DailyPostureStats] = [:]
    @Published var selectedDate: Date = Date()

    private var postureTimer: DispatchSourceTimer?

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
            peripherals.append(peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
            centralManager.stopScan()
            connectedPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            print("Connecting to \(peripheral.name ?? "Unknown")...")
            peripheral.delegate = self
            isConnected = true;
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
        stopPostureTracking()
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
 
            // determine if the posture data has changed, sending 1 means good
            let newIsGood = (status == 1)

    guard newIsGood != isPostureGood else { return }
        isPostureGood = newIsGood
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        connectedPeripheral = nil
        isConnected = false
        stopPostureTracking()
        isTracking = false
    }
    
    func stats(for date: Date) -> DailyPostureStats {
        let day = Calendar.current.startOfDay(for: date)

        return dailyStats[day] ??
            DailyPostureStats(
                date: day,
                goodTime: 0,
                badTime: 0
            )
    }

    
    func startPostureTracking() {
        guard !isTracking else { return }
        isTracking = true

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1)

        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.updateDailyTime(isGood: self.isPostureGood)
        }

        postureTimer = timer
        timer.resume()
    }

    
    private func updateDailyTime(isGood: Bool) {
        let today = startOfDay(Date())
        
        // Get current stats or create new
        var stats = dailyStats[today] ?? DailyPostureStats(date: today, goodTime: 0, badTime: 0)
        
        // Update stats
        if isGood {
            stats.goodTime += 1
        } else {
            stats.badTime += 1
        }
        
        // Reassign to trigger @Published
        dailyStats[today] = stats
    }



    func stopPostureTracking() {
        isTracking = false
        postureTimer?.cancel()
        postureTimer = nil
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


