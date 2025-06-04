// ContentView.swift
// YOGURT

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            Button("Send Hourly Now") {
                UploadService.shared.debugSendHourlyNow()
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
                UploadService.shared.debugSendHourlyNow()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
