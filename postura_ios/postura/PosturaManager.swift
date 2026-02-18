//
//  PosturaManager.swift
//  postura
//
//  Created by YunHao Dong on 12/31/25.
//


import Foundation
import Combine
import CoreBluetooth

class PosturaManager: NSObject, ObservableObject{

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
        return dailyStats[day, default: DailyPostureStats(
            date: day,
            goodTime: 0,
            badTime: 0
        )]
    }
    
    func startPostureTracking() {
        guard !bleManager.isTracking else { return }
        bleManager.isTracking = true

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1)

        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.updateDailyTime(isGood: bleManager.isPostureGood == 63)
            // 000 000 each pressure sensor is not fulfilled
            // 111 111 each pressure sensor is fulfilled
        }

        postureTimer = timer
        timer.resume()
        isTracking = true
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
        bleManager.isTracking = false
        isTracking = true
        postureTimer?.cancel()
        postureTimer = nil
    }
    
}
