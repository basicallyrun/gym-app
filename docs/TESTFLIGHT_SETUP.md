# TestFlight Deployment Setup Guide

This guide walks you through setting up automated TestFlight deployment for GymApp. Since you're on Linux without Mac access, all deployment happens through GitHub Actions.

## Overview

The deployment system uses:
- **Fastlane** - iOS automation framework
- **Fastlane Match** - Code signing certificate management
- **GitHub Actions** - CI/CD runner (macOS-15)
- **Private Git Repository** - Encrypted certificate storage

## Prerequisites

- Apple Developer Account ($99/year)
- GitHub account with access to this repository
- A private GitHub repository for certificate storage

## Setup Steps

### 1. Apple Developer Account Setup

#### 1.1 Create or Access Apple Developer Account
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in or create an account ($99/year membership required)
3. Complete enrollment process if new

#### 1.2 Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **+** (Add App)
3. Fill in app details:
   - **Platform**: iOS
   - **Name**: GymApp (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: Select `com.gymapp.GymApp` (or create new)
   - **SKU**: `gymapp-001` (or any unique identifier)
   - **User Access**: Full Access
4. Click **Create**

#### 1.3 Enable HealthKit Capability
1. In App Store Connect, go to your app → **App Information**
2. Scroll to **App Capabilities**
3. Enable **HealthKit**
4. Save changes

5. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
6. Select your app identifier (`com.gymapp.GymApp`)
7. Enable **HealthKit** capability
8. Click **Save**

### 2. Generate App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Security** → **App-Specific Passwords**
4. Click **+** to generate new password
5. Label it `GymApp-CI` or similar
6. **Copy the password** (you won't see it again)
7. Save this as `APP_STORE_CONNECT_API_KEY` secret

### 3. Get Team IDs

You need two different Team IDs:

#### 3.1 Apple Developer Team ID
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Click **Membership** in sidebar
3. Copy the **Team ID** (10-character alphanumeric)
4. Save this as `APPLE_TEAM_ID` secret

#### 3.2 App Store Connect Team ID
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click your name in top-right → **View Membership**
3. If you see a Team ID here, use it
4. Otherwise, it's usually the same as your Developer Team ID
5. Save this as `APP_STORE_CONNECT_TEAM_ID` secret

### 4. Create Private Certificates Repository

1. Go to GitHub and create a **new private repository**
2. Name it `gymapp-certificates` (or any name you prefer)
3. Make it **Private** (important for security)
4. Initialize with README (optional)
5. Copy the repository URL:
   ```
   https://github.com/YOUR_USERNAME/gymapp-certificates.git
   ```
6. Save this as `MATCH_GIT_URL` secret

### 5. Generate Match Password

This password encrypts your certificates in the Git repository.

Run this command on any system:
```bash
openssl rand -base64 32
```

Or use this online: [passwordsgenerator.net](https://passwordsgenerator.net/)

Save the generated password securely. You'll need it as `MATCH_PASSWORD` secret.

### 6. Create GitHub Personal Access Token (PAT)

You need TWO tokens:

#### 6.1 PAT for Match Git Access
1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Name it `GymApp Match Access`
4. Select scopes:
   - ✅ `repo` (full control of private repositories)
5. Click **Generate token**
6. **Copy the token** (save it securely)

#### 6.2 Create MATCH_GIT_BASIC_AUTH Secret
Encode your GitHub username and PAT:
```bash
echo -n "YOUR_GITHUB_USERNAME:YOUR_PAT" | base64
```

Save the output as `MATCH_GIT_BASIC_AUTH` secret.

#### 6.3 PAT for Pushing Commits
1. Generate another token with same settings
2. Name it `GymApp Build Number Commits`
3. Save this as `GH_PAT` secret

### 7. Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 8 secrets:

| Secret Name | Description | Example/Source |
|-------------|-------------|----------------|
| `APPLE_ID` | Your Apple Developer email | `developer@example.com` |
| `APPLE_TEAM_ID` | Developer Portal Team ID | `AB1C2D3E4F` (from step 3.1) |
| `APP_STORE_CONNECT_TEAM_ID` | App Store Connect Team ID | `12345678` (from step 3.2) |
| `APP_STORE_CONNECT_API_KEY` | App-specific password | `abcd-efgh-ijkl-mnop` (from step 2) |
| `MATCH_PASSWORD` | Encryption password for certificates | From step 5 |
| `MATCH_GIT_URL` | Private certificates repo URL | `https://github.com/user/gymapp-certificates.git` |
| `MATCH_GIT_BASIC_AUTH` | Base64 of `username:PAT` | From step 6.2 |
| `GH_PAT` | Personal Access Token for commits | From step 6.3 |

### 8. Initial Match Certificate Generation

**IMPORTANT**: This step requires a Mac or cloud Mac service.

Fastlane Match needs to generate certificates and provisioning profiles on first run.

#### Option A: If You Have Mac Access
```bash
cd /path/to/gym_app
bundle install
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export MATCH_PASSWORD="your-match-password"
export MATCH_GIT_URL="https://github.com/user/gymapp-certificates.git"
export MATCH_GIT_BASIC_AUTH="base64-encoded-credentials"

fastlane match appstore
```

#### Option B: Cloud Mac Service (Recommended for Linux Users)
Use a service like:
- [MacStadium](https://www.macstadium.com) - $1/hour Mac VM
- [MacinCloud](https://www.macincloud.com) - Pay-as-you-go Mac access
- [AWS EC2 Mac](https://aws.amazon.com/ec2/instance-types/mac/) - Mac instances

Steps:
1. Rent a Mac instance (1 hour is enough)
2. Install Xcode from App Store
3. Clone your repository
4. Run the commands from Option A
5. Certificates are now stored in your private repo
6. Terminate the Mac instance

#### Option C: Skip Initial Setup (Not Recommended)
The first GitHub Actions run will attempt to create certificates. This might fail if HealthKit capability isn't properly configured. Only use if Options A/B aren't feasible.

### 9. Test the Workflow

#### 9.1 Trigger First Deployment
1. Go to GitHub repository → **Actions** tab
2. Select **Deploy to TestFlight** workflow
3. Click **Run workflow** → **Run workflow**
4. Monitor the logs

#### 9.2 Expected Timeline
- **Workflow execution**: 10-15 minutes
- **TestFlight processing**: 5-15 minutes after upload
- **Total time to testable build**: ~20-30 minutes

#### 9.3 Verify in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **GymApp** → **TestFlight** tab
3. You should see your build under **iOS builds**
4. Wait for "Processing" to complete

#### 9.4 Add Internal Testers
1. In TestFlight tab, go to **Internal Testing**
2. Create a test group (e.g., "Internal Testers")
3. Add testers by email
4. Enable automatic distribution for new builds
5. Testers will receive email invitation

#### 9.5 Install on Device
1. Install **TestFlight app** from App Store
2. Open invitation email on iOS device
3. Tap **View in TestFlight**
4. Install the build
5. Test HealthKit permissions and core functionality

## Deployment Workflow Usage

### Manual Deployment
```bash
# Trigger from GitHub Actions UI
# Repository → Actions → Deploy to TestFlight → Run workflow
```

### Tag-Based Deployment
```bash
# Create and push a version tag (runs automatically)
git tag v1.0.1
git push origin v1.0.1
```

### Build Number Management
Build numbers auto-increment on each deployment. The workflow:
1. Reads `CURRENT_PROJECT_VERSION` from `project.yml`
2. Increments by 1
3. Commits back with `[skip ci]` tag
4. Pushes to repository

## Troubleshooting

### "No profiles found" or "Profile doesn't include HealthKit"
**Cause**: HealthKit capability not enabled in App Store Connect

**Solution**:
1. Enable HealthKit in App Store Connect (App Information → Capabilities)
2. Enable HealthKit in Developer Portal (Identifiers → App ID → Edit)
3. Delete existing profiles from certificates repo
4. Re-run Match: `fastlane match appstore --force`

### "Invalid username/password"
**Cause**: App-specific password expired or incorrect

**Solution**:
1. Generate new app-specific password at appleid.apple.com
2. Update `APP_STORE_CONNECT_API_KEY` secret in GitHub

### "Build already uploaded" or "Duplicate build number"
**Cause**: Build number wasn't incremented

**Solution**:
1. Check if commit was pushed (look for build number bump commit)
2. Manually increment in `project.yml` if needed
3. Ensure `GH_PAT` has push permissions

### "Could not find or access Match repository"
**Cause**: Invalid `MATCH_GIT_URL` or `MATCH_GIT_BASIC_AUTH`

**Solution**:
1. Verify certificates repository exists and is private
2. Check `MATCH_GIT_BASIC_AUTH` is correctly base64-encoded
3. Ensure PAT has `repo` scope
4. Test access: `git clone MATCH_GIT_URL` with credentials

### "Code signing error" or "Provisioning profile expired"
**Cause**: Certificates or profiles expired (valid for 1 year)

**Solution**:
```bash
# Regenerate certificates (requires Mac)
fastlane match nuke distribution
fastlane match appstore
```

### Workflow Fails at "Upload to TestFlight"
**Cause**: Various (network, App Store Connect issues, app rejection)

**Solution**:
1. Check Fastlane logs in Actions artifacts
2. Verify app exists in App Store Connect
3. Check for any compliance warnings in App Store Connect
4. Ensure export compliance is configured (if required)

### "Could not find Xcode project"
**Cause**: XcodeGen failed to generate project

**Solution**:
1. Check `project.yml` syntax is valid YAML
2. Ensure all source files referenced exist
3. Run locally: `xcodegen generate`

## Certificate Renewal

Distribution certificates expire after 1 year. To renew:

1. **30 days before expiry**, Match will warn you
2. Regenerate certificates:
   ```bash
   fastlane match nuke distribution  # Revokes old
   fastlane match appstore           # Creates new
   ```
3. Next deployment will use new certificates automatically

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Keep certificates repository private**
3. **Rotate PATs** every 6-12 months
4. **Use separate PATs** for different purposes
5. **Enable 2FA** on Apple ID
6. **Review GitHub Actions logs** for sensitive data leaks
7. **Limit PAT scopes** to minimum required
8. **Back up Match password** securely (password manager)

## Workflow Comparison

You now have two workflows:

| Workflow | Purpose | Trigger | Duration | Requires Secrets |
|----------|---------|---------|----------|------------------|
| `build.yml` | Fast validation | Every push | 2-3 min | No |
| `testflight.yml` | TestFlight deployment | Manual/tags | 10-15 min | Yes |

## Next Steps

After successful TestFlight deployment:

1. **External Testing**: Add external testers in App Store Connect
2. **Automated Testing**: Add UI tests to workflow before deployment
3. **Release Notes**: Automate changelog generation
4. **Crash Reporting**: Integrate Crashlytics or Sentry
5. **App Store Submission**: Create `release` lane in Fastlane

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Review this troubleshooting section
3. Check Fastlane documentation: [docs.fastlane.tools](https://docs.fastlane.tools)
4. GitHub Issues for this project

## Resources

- [Fastlane Documentation](https://docs.fastlane.tools)
- [Fastlane Match Guide](https://docs.fastlane.tools/actions/match/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)
