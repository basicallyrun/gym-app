# GymApp

A SwiftUI iOS application for fitness and workout tracking with HealthKit integration.

## Features

- HealthKit integration for workout data
- Modern SwiftUI interface
- iOS 17.0+ support

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Development Setup

### Prerequisites

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

### Building the Project

1. Generate Xcode project:
   ```bash
   xcodegen generate
   ```

2. Open the project:
   ```bash
   open GymApp.xcodeproj
   ```

3. Select a simulator or device and build (⌘+B)

## Project Structure

```
GymApp/
├── GymApp.swift          # App entry point
├── Models/               # Data models
├── ViewModels/           # Business logic
├── Services/             # HealthKit and other services
├── Views/                # SwiftUI views
├── Resources/            # Assets and resources
├── Info.plist            # App configuration
├── GymApp.entitlements   # App capabilities (HealthKit)
└── project.yml           # XcodeGen configuration
```

## CI/CD

This project uses GitHub Actions for continuous integration and deployment:

### Build Validation Workflow (`build.yml`)
- **Triggers**: Every push and pull request
- **Purpose**: Fast validation of code changes
- **Duration**: ~2-3 minutes
- **Actions**:
  - Lints code
  - Generates Xcode project
  - Builds app for simulator
  - Runs unit tests (when added)

### TestFlight Deployment Workflow (`testflight.yml`)
- **Triggers**: Manual or version tags (`v*`)
- **Purpose**: Build and deploy to TestFlight
- **Duration**: ~10-15 minutes
- **Actions**:
  - Auto-increments build number
  - Syncs code signing certificates
  - Builds release IPA
  - Uploads to TestFlight
  - Commits build number bump

See [TestFlight Setup Guide](docs/TESTFLIGHT_SETUP.md) for detailed deployment configuration.

## HealthKit Setup

The app requires HealthKit permissions to function properly.

### Required Capabilities
- HealthKit enabled in `GymApp.entitlements`
- Privacy usage descriptions in `Info.plist`

### Permissions Requested
- Workouts (read/write)
- Active Energy Burned (read)
- Exercise Time (read)

## Configuration

### App Settings
Configured in `project.yml`:
- Bundle ID: `com.gymapp.GymApp`
- Deployment Target: iOS 17.0
- Marketing Version: 1.0.0
- Build Number: Auto-incremented in CI

### Code Signing
- Development: Automatic signing (local development)
- Distribution: Fastlane Match (CI/CD)

## Testing

Run tests in Xcode:
```bash
xcodebuild test -scheme GymApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or use Xcode's Test Navigator (⌘+6).

## Deployment

### TestFlight Deployment

1. Ensure all [TestFlight setup steps](docs/TESTFLIGHT_SETUP.md) are complete
2. Trigger deployment:
   - **Manual**: GitHub Actions → Deploy to TestFlight → Run workflow
   - **Automatic**: Push version tag: `git tag v1.0.1 && git push origin v1.0.1`
3. Wait ~20-30 minutes for build to appear in TestFlight
4. Install via TestFlight app on iOS device

### Build Numbers
Build numbers are automatically incremented during CI deployment. Current build number is stored in `project.yml` under `CURRENT_PROJECT_VERSION`.

## Troubleshooting

### Xcode Project Issues
If the Xcode project is corrupted or missing:
```bash
xcodegen generate
```

### HealthKit Permissions Not Showing
1. Check `GymApp.entitlements` has HealthKit enabled
2. Verify `Info.plist` has privacy usage descriptions
3. Ensure HealthKit capability is enabled in App Store Connect

### Build Failures
- Check GitHub Actions logs for detailed error messages
- Verify all required secrets are configured
- See [TestFlight Setup Guide](docs/TESTFLIGHT_SETUP.md) troubleshooting section

## Contributing

1. Create a feature branch
2. Make changes
3. Ensure build workflow passes
4. Submit pull request

## License

[Your License Here]

## Support

For deployment issues, see [docs/TESTFLIGHT_SETUP.md](docs/TESTFLIGHT_SETUP.md).
