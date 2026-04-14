import Foundation
import Combine
import CoreBluetooth

class PosturaManager: NSObject, ObservableObject {

    @Published var isTracking = false
    @Published var dailyStats: [Date: DailyPostureStats] = [:]
    @Published var selectedDate: Date = Date()
    let bleManager: BLEManager

    private var postureTimer: DispatchSourceTimer?
    private var cancellables = Set<AnyCancellable>()

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        super.init()
        bleManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                if !connected {
                    self?.stopPostureTracking()
                }
            }
            .store(in: &cancellables)
    }

    func stats(for date: Date) -> DailyPostureStats {
        let day = Calendar.current.startOfDay(for: date)
        return dailyStats[day, default: DailyPostureStats(date: day, goodTime: 0, badTime: 0)]
    }

    func startPostureTracking() {
        guard !isTracking else { return }
        guard bleManager.isConnected else {
            print("startPostureTracking failed — not connected")
            return
        }

        bleManager.isTracking = true
        isTracking = true

        if bleManager.isReady {
            bleManager.writeCommand(3)
            print("Command sent immediately")
        } else {
            bleManager.$isReady
                .filter { $0 }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.bleManager.writeCommand(3)
                    print("Command sent after characteristics discovered")
                }
                .store(in: &cancellables)
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)

        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard let status = self.bleManager.PostureStatus else {
                print("Timer fired but PostureStatus is nil — waiting for data")
                return
            }
            print("Timer fired, status: \(status)")
            self.updateDailyTime(isGood: status == 1)
        }

        postureTimer = timer
        timer.resume()
    }

    private func updateDailyTime(isGood: Bool) {
        let today = startOfDay(Date())
        var stats = dailyStats[today] ?? DailyPostureStats(date: today, goodTime: 0, badTime: 0)
        if isGood {
            stats.goodTime += 1
        } else {
            stats.badTime += 1
        }
        dailyStats[today] = stats
    }

    func stopPostureTracking() {
        bleManager.isTracking = false
        isTracking = false
        postureTimer?.cancel()
        postureTimer = nil
        bleManager.writeCommand(0)
    }
}
