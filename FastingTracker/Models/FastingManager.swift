import Foundation
import SwiftUI

class FastingManager: ObservableObject {
    @Published var currentFast: Fast?
    @Published var completedFasts: [Fast] = []

    private let currentFastKey = "currentFast"
    private let completedFastsKey = "completedFasts"

    init() {
        loadData()
    }

    func startFast(goalHours: Int = 16) {
        let fast = Fast(goalHours: goalHours)
        currentFast = fast
        saveData()
    }

    func endFast() {
        guard var fast = currentFast else { return }
        fast.endTime = Date()
        completedFasts.insert(fast, at: 0)
        currentFast = nil
        saveData()
    }

    private func saveData() {
        if let currentFast = currentFast {
            if let encoded = try? JSONEncoder().encode(currentFast) {
                UserDefaults.standard.set(encoded, forKey: currentFastKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: currentFastKey)
        }

        if let encoded = try? JSONEncoder().encode(completedFasts) {
            UserDefaults.standard.set(encoded, forKey: completedFastsKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: currentFastKey),
           let fast = try? JSONDecoder().decode(Fast.self, from: data) {
            currentFast = fast
        }

        if let data = UserDefaults.standard.data(forKey: completedFastsKey),
           let fasts = try? JSONDecoder().decode([Fast].self, from: data) {
            completedFasts = fasts
        }
    }
}
