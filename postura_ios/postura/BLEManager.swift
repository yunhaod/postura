import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject,
                  CBCentralManagerDelegate, CBPeripheralDelegate {

    @Published var connectedPeripheral: CBPeripheral?
    @Published var isConnected: Bool = false
    @Published var isTracking = false
    @Published var PostureStatus: Int8? = nil
    @Published var peripherals: [CBPeripheral] = []
    @Published var isReady: Bool = false

    var centralManager: CBCentralManager!

    var PostureServiceUUID = CBUUID(string: "a3721400-00b0-4240-ba50-05ca45bf8abc")
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
        centralManager.scanForPeripherals(withServices: [PostureServiceUUID], options: nil)
        print("Scanning...")
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
        }
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("Connecting to \(peripheral.name ?? "Unknown")...")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        isConnected = true
        PostureStatus = nil
        peripheral.discoverServices([PostureServiceUUID])
        print("Connected to \(peripheral.name ?? "Unknown")")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == PostureCharacteristicUUID {
                guard CommandCharacteristic == nil else { continue }
                print("Found PostureChar, subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == CommandCharacteristicUUID {
                guard CommandCharacteristic == nil else { continue }
                CommandCharacteristic = characteristic
                print("Found CommandChar")
                isReady = true
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Error receiving update: \(error)")
            return
        }
        guard let data = characteristic.value,
              let rawStatus = data.first else { return }

        let newStatus = Int8(bitPattern: rawStatus)
        guard newStatus != PostureStatus else { return }

        DispatchQueue.main.async {
            self.PostureStatus = newStatus
            print("Posture updated: \(newStatus)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        connectedPeripheral = nil
        isConnected = false
        isTracking = false
        isReady = false
        CommandCharacteristic = nil
        PostureStatus = nil
        print("Disconnected")
    }

    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        connectedPeripheral = nil
        isConnected = false
        isTracking = false
        isReady = false
        CommandCharacteristic = nil
        PostureStatus = nil
    }

    func writeCommand(_ value: UInt8) {
        print("writeCommand called with value: \(value)")
        print("connectedPeripheral: \(String(describing: connectedPeripheral))")
        print("CommandCharacteristic: \(String(describing: CommandCharacteristic))")
        guard let peripheral = connectedPeripheral,
              let characteristic = CommandCharacteristic else {
            print("writeCommand failed — not connected or CommandChar not found")
            return
        }
        peripheral.writeValue(Data([value]), for: characteristic, type: .withResponse)
        print("Wrote command: \(value)")
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
