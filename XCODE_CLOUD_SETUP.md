# Setting Up Xcode Cloud for LogSnap

This document provides step-by-step instructions for setting up Xcode Cloud CI/CD for the LogSnap project.

## Prerequisites

1. An Apple Developer Program membership
2. Xcode 13.0 or later
3. Your LogSnap project in a GitHub repository (this one)
4. App Store Connect access

## Step 1: Connect Your Repository

1. Open your project in Xcode
2. Go to **Product > Xcode Cloud > Create Workflow...**
3. Sign in with your Apple ID if prompted
4. Select GitHub as your source control provider
5. Authorize Xcode Cloud to access your GitHub repositories
6. Select the LogSnap repository

## Step 2: Configure Your Workflow

1. Define your workflow settings:
   - **Name**: LogSnap CI
   - **Branch**: main (or your preferred primary branch)
   - **Actions**: Build, Test, Archive

2. Configure the build settings:
   - Select the appropriate scheme: "LogSnap"
   - Choose the platforms to build for (iOS)
   - Select devices for testing

3. Set up post-actions (optional):
   - Deploy to TestFlight
   - Notify team members

## Step 3: Start Your First Build

1. Commit and push any pending changes to your repository
2. Go to **Product > Xcode Cloud > View Workflows**
3. Select your workflow and click "Start Build"

## Step 4: Monitor Your Builds

1. In Xcode, navigate to the Cloud tab to see build status
2. You can also check build status in App Store Connect:
   - Go to appstoreconnect.apple.com
   - Navigate to "Apps" > "Your App" > "TestFlight" > "Builds"

## Troubleshooting

- **Build Failures**: Check the build logs for specific errors
- **Configuration Issues**: Verify your Xcode project settings
- **Authorization Problems**: Reconnect GitHub in App Store Connect

## Advanced Options

- Set up multiple workflows for different branches
- Configure conditional workflows based on changes
- Customize environment variables for build configurations
- Set up automatic TestFlight distribution to internal testers