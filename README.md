# YOGURT

This repository contains the **YOGURT** iOS application. The project is maintained as an Xcode project (`YoGurt.xcodeproj`).

## Build prerequisites

- macOS with **Xcode 15** or later
- A recent iOS SDK (the project currently targets iOS 18.0+)
- An Apple developer account for running on device

## Running the app

1. Open `YoGurt.xcodeproj` in Xcode.
2. Select the `YoGurt` scheme.
3. Build and run the application using a simulator or a connected iOS device (`⌘R`).

## Running tests

Tests are **Xcode-based**. To execute them:

1. Open the project in Xcode.
2. Choose the `YoGurt` scheme for unit tests or the `YoGurtUITests` scheme for UI tests.
3. Run the tests with `Product ▸ Test` (`⌘U`).

No `Package.swift` file is provided, so the Swift Package Manager is not used for building or testing this project.
