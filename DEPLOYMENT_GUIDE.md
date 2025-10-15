# KODUGE KART - Deployment Guide

## 📋 Prerequisites

- Flutter SDK 3.7.2 or higher
- Firebase account
- Android Studio / Xcode (for mobile deployment)
- Firebase CLI: `npm install -g firebase-tools`

## 🚀 Initial Setup

### 1. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd KODUGE-KART
flutter pub get
```

### 2. Firebase Setup

#### A. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing: `foodshareconnect-d9939`
3. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage (if using images)

#### B. Configure Firebase for Android

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# Select:
# - Firestore
# - Hosting (optional)
```

Generate `google-services.json`:
```bash
cd android/app
# Download google-services.json from Firebase Console
# Place it in android/app/
```

#### C. Configure Firebase for Web

```bash
# Generate firebase_options.dart
flutterfire configure --project=foodshareconnect-d9939
```

### 3. Deploy Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

### 4. Deploy Firestore Security Rules

Create `firestore.rules` in project root:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /user/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /donorfood/{donationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.donorId == request.auth.uid;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && resource.data.donorId == request.auth.uid;
    }
    
    match /ngofood/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.ngoId == request.auth.uid;
      allow update: if request.auth != null && resource.data.ngoId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.ngoId == request.auth.uid;
    }
    
    match /notifications/{notificationId} {
      allow read: if request.auth != null && resource.data.recipientId == request.auth.uid;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.recipientId == request.auth.uid;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only firestore:rules
```

## 📱 Running the App

### Development Mode

```bash
# Check Flutter setup
flutter doctor

# Run on Android
flutter run

# Run on Web
flutter run -d chrome

# Run on iOS
flutter run -d ios
```

### Build for Production

#### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
flutter build ios --release
# Then open Xcode to archive and upload
```

#### Web

```bash
flutter build web --release
# Output: build/web/

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## 🔧 Configuration Files

### Required Files (Not in Git)

Create these files locally:

1. **android/app/google-services.json** - Download from Firebase Console
2. **lib/firebase_options.dart** - Generate with `flutterfire configure`
3. **android/key.properties** - For Android signing:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore>
```

## 🔐 Security Checklist

- [ ] Firebase API keys regenerated (if previously exposed)
- [ ] Firestore security rules deployed
- [ ] Firestore indexes deployed
- [ ] Email/Password authentication enabled in Firebase
- [ ] Email verification enabled
- [ ] Sensitive files added to .gitignore
- [ ] App signing configured (for production)

## 📊 Firestore Indexes Status

Check index creation status:
```bash
firebase firestore:indexes
```

All indexes should show as "READY" before running the app.

## 🧪 Testing

### Test Authentication
1. Register a new user (both Donor and NGO)
2. Verify email from inbox
3. Login with verified account
4. Test password reset

### Test Donor Flow
1. Login as donor
2. Create a donation with items
3. View matched NGOs
4. Check donation history

### Test NGO Flow
1. Login as NGO
2. Create a request with items
3. View available donations
4. Accept a donation
5. Mark as fulfilled

### Test Matching
1. Create donor donation with items: Rice (10kg), Wheat (5kg)
2. Create NGO request with items: Rice (5kg), Pulses (2kg)
3. Verify matching appears in both accounts
4. Verify match score calculation

## 🐛 Common Issues

### Issue: Firebase not initialized
**Solution**: Ensure `google-services.json` and `firebase_options.dart` are present

### Issue: Firestore permission denied
**Solution**: Deploy security rules: `firebase deploy --only firestore:rules`

### Issue: Composite index error
**Solution**: Deploy indexes: `firebase deploy --only firestore:indexes`

### Issue: Email verification not working
**Solution**: Check Firebase Console → Authentication → Templates

### Issue: Build fails on Android
**Solution**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 📈 Monitoring

### Firebase Console Monitoring

1. **Authentication**: Monitor user signups and logins
2. **Firestore**: Check read/write operations
3. **Performance**: Monitor app performance
4. **Crashlytics** (optional): Track crashes

### Enable Analytics

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_analytics: ^10.x.x
```

## 🔄 Updates and Maintenance

### Update Dependencies

```bash
flutter pub upgrade
flutter pub outdated
```

### Update Firebase

```bash
flutterfire configure
firebase deploy
```

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## 👥 Team Setup

For new team members:

1. Install Flutter and Firebase CLI
2. Get sensitive files securely (not via Git):
   - `google-services.json`
   - `firebase_options.dart`
   - `key.properties` (for release builds)
3. Run `flutter pub get`
4. Run `flutter run`

## 🚀 CI/CD (Optional)

### GitHub Actions Example

Create `.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.32.4'
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test
    - run: flutter build apk
```

## 📞 Support

For issues or questions:
1. Check Flutter doctor: `flutter doctor -v`
2. Check Firebase Console for errors
3. Review logs: `flutter logs`
4. Clear cache: `flutter clean`

---

**Last Updated**: October 14, 2025
**App Version**: 1.0.0
**Flutter Version**: 3.32.4

