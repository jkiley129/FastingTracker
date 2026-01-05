import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let currentFast = fastingManager.currentFast {
                    FastingTimerView(fast: currentFast)
                } else {
                    Text("No active fast")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    if fastingManager.currentFast != nil {
                        fastingManager.endFast()
                    } else {
                        fastingManager.startFast()
                    }
                }) {
                    Text(fastingManager.currentFast != nil ? "End Fast" : "Start Fast")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(fastingManager.currentFast != nil ? Color.red : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                NavigationLink("Fasting History") {
                    HistoryView()
                }
                .padding(.bottom)
            }
            .navigationTitle("Fasting Tracker")
        }
    }
}

struct FastingTimerView: View {
    let fast: Fast
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("Fasting")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()

            ProgressRing(progress: progress)
                .frame(width: 200, height: 200)

            Text("Goal: \(fast.goalHours) hours")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var timeString: String {
        let elapsed = currentTime.timeIntervalSince(fast.startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) / 60 % 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var progress: Double {
        let elapsed = currentTime.timeIntervalSince(fast.startTime)
        let goalSeconds = Double(fast.goalHours) * 3600
        return min(elapsed / goalSeconds, 1.0)
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.title)
                .bold()
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        List {
            ForEach(fastingManager.completedFasts) { fast in
                VStack(alignment: .leading, spacing: 4) {
                    Text(fast.startTime, style: .date)
                        .font(.headline)
                    Text("Duration: \(fast.formattedDuration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("History")
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingManager())
}
