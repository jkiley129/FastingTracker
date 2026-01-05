import Foundation

struct Fast: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let goalHours: Int

    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil, goalHours: Int = 16) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.goalHours = goalHours
    }

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        guard let duration = duration else { return "In progress" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return "\(hours)h \(minutes)m"
    }

    var isComplete: Bool {
        endTime != nil
    }
}
