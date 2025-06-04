// ContentView.swift
// YOGURT

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            Button("Send Hourly Now") {
                HealthKitManager.shared.collectHourlyMetrics { metrics in
                    UploadService.shared.uploadHourlyMetricsOnce(metrics)
                }
            }
        }
        .padding()
        .onAppear {
            HealthKitManager.shared.requestAuthorization { ok, err in
                print("HealthKit auth:", ok, err ?? "")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("🔔 Scene became active — forcing data sync")
                HealthKitManager.shared.collectHourlyMetrics { metrics in
                    UploadService.shared.uploadHourlyMetricsOnce(metrics)
                }
                HealthKitManager.shared.collectCombinedSleepAnalysis {
                    if let sleep = $0 {
                        UploadService.shared.uploadSleepAnalysis(sleep)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
