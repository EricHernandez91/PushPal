# PushPal 💪

A modern iOS app for tracking pushups with AI-powered pose detection, group challenges, and social accountability.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange)
![Vision](https://img.shields.io/badge/Vision-Framework-green)

## Features

### 🎯 Core Features

- **AI Camera Tracking** - Real-time pushup counting using Apple's Vision framework for body pose detection
- **Form Analysis** - Get instant feedback on your pushup form with percentage scores
- **Personal Stats** - Track daily, weekly, and monthly progress with beautiful charts
- **Streak Tracking** - Maintain your workout streak and hit daily goals
- **Personal Records** - Track your best sets, best days, and all-time totals

### 👥 Social Features

- **Groups** - Create or join groups with friends using invite codes
- **Leaderboards** - Compete with group members on weekly pushup counts
- **Challenges** - Create group challenges with targets and deadlines
- **Notifications** - Get reminders to workout and notifications when friends are active

### ✨ User Experience

- **Dark Theme** - Beautiful dark UI designed for fitness apps
- **Onboarding** - Smooth setup flow for new users
- **Confetti Celebrations** - Celebrate personal records with animations
- **Haptic Feedback** - Tactile feedback for each rep counted

## Screenshots

The app includes:
1. **Workout Screen** - Camera view with real-time pose detection
2. **Stats Dashboard** - Charts and personal records
3. **Groups** - Social features and leaderboards
4. **Settings** - Profile customization and notifications

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **Vision Framework** - Human body pose detection
- **AVFoundation** - Camera capture and preview
- **Charts** - Native SwiftUI charts for statistics
- **UserDefaults** - Local data persistence
- **CloudKit** (ready) - Backend for group syncing
- **UserNotifications** - Push notifications

## Requirements

- iOS 17.0+
- Xcode 15.0+
- iPhone with front-facing camera
- Physical device required for camera testing

## Installation

1. Open `PushPal.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on a physical iOS device

> ⚠️ **Note:** Camera features require a physical device. The simulator cannot access the camera.

## How Pose Detection Works

The app uses Vision's `VNDetectHumanBodyPoseRequest` to:

1. Capture video frames from the front camera
2. Detect body joints (shoulders, elbows, wrists, hips)
3. Calculate elbow angle to detect pushup phases (up/down)
4. Count reps when a complete up-down-up cycle is detected
5. Analyze body alignment for form scoring

### Detected Phases
- **Up** - Arms extended (elbow angle > 140°)
- **Going Down** - Transitioning to bottom
- **Down** - At bottom position (elbow angle < 110°)
- **Going Up** - Pushing back up

## Project Structure

```
PushPal/
├── PushPalApp.swift          # App entry point
├── ContentView.swift          # Main tab view
├── Views/
│   ├── CameraView.swift       # Workout camera screen
│   ├── CameraPreview.swift    # AVFoundation preview
│   ├── StatsView.swift        # Statistics dashboard
│   ├── GroupsView.swift       # Groups list
│   ├── GroupDetailView.swift  # Group details & leaderboard
│   ├── CreateGroupView.swift  # New group form
│   ├── ChallengeView.swift    # Challenge creation
│   ├── SettingsView.swift     # Settings & profile
│   ├── WorkoutCompleteView.swift  # Post-workout summary
│   └── OnboardingView.swift   # First-run setup
├── Services/
│   ├── PoseDetectionService.swift  # Vision pose detection
│   ├── DataManager.swift      # Data persistence
│   ├── NotificationManager.swift   # Push notifications
│   └── CloudKitManager.swift  # Cloud sync (ready)
├── Models/
│   ├── Models.swift           # Data models
│   └── WorkoutSession.swift   # Active workout state
└── Assets.xcassets/           # App icons & colors
```

## CloudKit Setup (Optional)

To enable group syncing:

1. Enable CloudKit in Signing & Capabilities
2. Create a CloudKit container: `iCloud.com.pushpal.app`
3. Add record types matching the CloudKitManager schemas
4. Enable push notifications for real-time updates

## TODOs for v2

- [ ] Apple Health integration
- [ ] Watch app companion
- [ ] Exercise variations (squats, sit-ups)
- [ ] Video recording of workouts
- [ ] Social sharing with workout clips
- [ ] Achievement badges system
- [ ] Workout history calendar view
- [ ] Export workout data
- [ ] Widget for daily progress
- [ ] Siri shortcuts ("Hey Siri, start pushups")
- [ ] Live Activities for ongoing workouts
- [ ] Backend migration to Firebase/Supabase for better real-time sync

## Known Limitations

- Pose detection works best in good lighting
- User should be 3-6 feet from camera
- Side profile or angled views may reduce accuracy
- Some false positives possible during rapid movements

## License

MIT License - feel free to use and modify!

---

Built with ❤️ using SwiftUI and Vision Framework
