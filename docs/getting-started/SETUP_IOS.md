# iOS Setup Guide

This guide details the steps to set up the iOS development environment for ShamelaGPT.

## Prerequisites
- **macOS** 13.5 (Ventura) or newer.
- **Xcode 15.0** or newer.
- **CocoaPods** (if not using Swift Package Manager exclusively).

## Getting Started

1. **Clone the project**:
   ```bash
   git clone https://github.com/your-org/ShamelaGPT.git
   cd ShamelaGPT/shamelagpt-ios
   ```

2. **Dependency Installation**:
   If the project uses CocoaPods:
   ```bash
   pod install
   ```
   If using Swift Package Manager, Xcode will resolve dependencies automatically upon opening.

3. **Open the Project**:
   - Open `ShamelaGPT.xcworkspace` (if using Pods).
   - Or open `ShamelaGPT.xcodeproj` (if using SPM only).

4. **Signing & Capabilities**:
   - Select the `shamelagpt` target in the project settings.
   - Go to "Signing & Capabilities".
   - Select your development team.
   - Change the "Bundle Identifier" if necessary to avoid conflicts.

## Project Structure
- `App/`: Main app entry and lifecycle.
- `Presentation/`: SwiftUI Views and ViewModels.
- `Domain/`: Business logic and Use Cases.
- `Data/`: Repositories and local/remote data sources.
- `Core/`: Networking, storage utilities, and extensions.

## Running the App
- Select a simulator (iPhone 15 or newer recommended).
- Press `Cmd + R` or click the Play button in Xcode.

## Running Tests

### Unit Tests
- Press `Cmd + U` to run all unit and UI tests.
- Navigate to the **Test Navigator** (`Cmd + 6`) to run specific tests.

### UI Tests
- Select the `ShamelaGPTUITests` scheme.
- Run tests as usual. Note that UI tests may require a clean simulator state.

## Feature Flags & Environment
Environment variables can be passed via the Xcode Scheme:
- `UI_TESTING`: Set to `1` to use mock network data.
- `BASE_URL`: Override default API endpoint.

## Troubleshooting
Refer to [TROUBLESHOOTING_IOS.md](TROUBLESHOOTING_IOS.md) for common issues.
