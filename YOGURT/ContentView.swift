// ContentView.swift
// YOGURT

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            Button("Send Hourly Now") {
                HealthDataFetcher.shared.fetchAllHealthData { payload in
                    UploadService.shared.uploadIfNeeded(metrics: payload.metrics)
                    UploadService.shared.uploadIfNeeded(sleep: payload.sleep)
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
                HealthDataFetcher.shared.fetchAllHealthData { payload in
                    UploadService.shared.uploadIfNeeded(metrics: payload.metrics)
                    UploadService.shared.uploadIfNeeded(sleep: payload.sleep)
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
