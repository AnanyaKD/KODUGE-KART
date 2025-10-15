# AuthController API Reference

## Overview

The `AuthController` is a GetX-based controller that manages all authentication operations in the KODUGE KART app. It provides a clean, modular interface for user authentication, registration, and session management.

## Getting Started

### Import the Controller

```dart
import 'package:koduge_kart/controllers/auth_controller.dart';
import 'package:get/get.dart';
```

### Access the Controller

```dart
// In any widget
final authController = Get.find<AuthController>();
```

## Core Methods

### 1. login()

Authenticates a user with email and password.

```dart
Future<bool> login({
  required String email,
  required String password,
  required BuildContext context,
})
```

**Parameters:**
- `email` (String, required): User's email address
- `password` (String, required): User's password
- `context` (BuildContext, required): Current build context for navigation

**Returns:** `Future<bool>`
- `true`: Login successful, user navigated to home screen
- `false`: Login failed, check `errorMessage` for details

**Example:**
```dart
final success = await authController.login(
  email: emailController.text,
  password: passController.text,
  context: context,
);

if (!success) {
  // Handle error
  print(authController.errorMessage.value);
}
```

**Features:**
- Email verification check
- Automatic navigation to Donor/NGO home based on user type
- Comprehensive error handling
- Loading state management

---

### 2. register()

Registers a new user account.

```dart
Future<bool> register({
  required String name,
  required String email,
  required String phone,
  required String address,
  required String password,
  required UserType userType,
  required BuildContext context,
})
```

**Parameters:**
- `name` (String, required): User's full name
- `email` (String, required): User's email address
- `phone` (String, required): User's phone number (10 digits)
- `address` (String, required): User's address
- `password` (String, required): User's password
- `userType` (UserType, required): Either `UserType.donor` or `UserType.ngo`
- `context` (BuildContext, required): Current build context

**Returns:** `Future<bool>`
- `true`: Registration successful
- `false`: Registration failed, check `errorMessage`

**Example:**
```dart
final success = await authController.register(
  name: 'John Doe',
  email: 'john@example.com',
  phone: '1234567890',
  address: '123 Main St',
  password: 'SecurePass123',
  userType: UserType.donor,
  context: context,
);

if (success) {
  // Show success message and navigate back to login
  Navigator.pop(context);
}
```

**Features:**
- Creates Firebase Auth account
- Saves user data to Firestore
- Optional email verification (commented out)
- Input validation
- Error handling for duplicate emails

---

### 3. sendPasswordResetEmail()

Sends a password reset email to the user.

```dart
Future<bool> sendPasswordResetEmail(String email)
```

**Parameters:**
- `email` (String, required): Email address to send reset link

**Returns:** `Future<bool>`
- `true`: Email sent successfully
- `false`: Failed to send email, check `errorMessage`

**Example:**
```dart
final success = await authController.sendPasswordResetEmail(
  'user@example.com',
);

if (success) {
  // Show success message
  print('Password reset email sent!');
} else {
  // Show error
  print(authController.errorMessage.value);
}
```

---

### 4. logout()

Signs out the current user.

```dart
Future<void> logout()
```

**Parameters:** None

**Returns:** `Future<void>`

**Example:**
```dart
await authController.logout();
// User is now signed out
```

**Features:**
- Clears Firebase Auth session
- Logs logout event
- Call `Get.offAll()` or navigate manually after logout

---

### 5. resendVerificationEmail()

Resends email verification to current user.

```dart
Future<bool> resendVerificationEmail()
```

**Parameters:** None

**Returns:** `Future<bool>`
- `true`: Verification email sent
- `false`: Failed or user already verified

**Example:**
```dart
final success = await authController.resendVerificationEmail();
if (success) {
  print('Verification email sent!');
}
```

---

## Helper Methods

### isLoggedIn()

Checks if a user is currently logged in.

```dart
bool isLoggedIn()
```

**Returns:** `bool`
- `true`: User is logged in
- `false`: No user logged in

**Example:**
```dart
if (authController.isLoggedIn()) {
  // User is logged in
  navigateToHome();
} else {
  // Show login screen
  navigateToLogin();
}
```

---

### getCurrentUserId()

Gets the current user's unique ID.

```dart
String? getCurrentUserId()
```

**Returns:** `String?`
- User ID if logged in
- `null` if not logged in

**Example:**
```dart
final userId = authController.getCurrentUserId();
if (userId != null) {
  // Fetch user-specific data
  fetchUserData(userId);
}
```

---

### getCurrentUserEmail()

Gets the current user's email address.

```dart
String? getCurrentUserEmail()
```

**Returns:** `String?`
- Email address if logged in
- `null` if not logged in

**Example:**
```dart
final email = authController.getCurrentUserEmail();
print('Logged in as: $email');
```

---

### isNGOUser()

Checks if the current user is an NGO.

```dart
Future<bool> isNGOUser()
```

**Returns:** `Future<bool>`
- `true`: Current user is NGO
- `false`: Current user is Donor or not logged in

**Example:**
```dart
final isNGO = await authController.isNGOUser();
if (isNGO) {
  // Show NGO-specific features
  showNGODashboard();
}
```

---

### isDonorUser()

Checks if the current user is a Donor.

```dart
Future<bool> isDonorUser()
```

**Returns:** `Future<bool>`
- `true`: Current user is Donor
- `false`: Current user is NGO or not logged in

**Example:**
```dart
final isDonor = await authController.isDonorUser();
if (isDonor) {
  // Show Donor-specific features
  showDonorDashboard();
}
```

---

### getCurrentUserData()

Fetches complete user data from Firestore.

```dart
Future<Map<String, dynamic>?> getCurrentUserData()
```

**Returns:** `Future<Map<String, dynamic>?>`
- User data map if logged in
- `null` if not logged in or error

**Example:**
```dart
final userData = await authController.getCurrentUserData();
if (userData != null) {
  print('Name: ${userData['name']}');
  print('Email: ${userData['email']}');
  print('Phone: ${userData['phone']}');
  print('Address: ${userData['address']}');
  print('User Type: ${userData['userType']}');
}
```

**User Data Structure:**
```dart
{
  'name': String,
  'email': String,
  'phone': String,
  'address': String,
  'userType': String,  // "UserType.donor" or "UserType.ngo"
  'emailVerified': bool,
  'createdAt': Timestamp,
}
```

---

### clearError()

Clears the current error message.

```dart
void clearError()
```

**Parameters:** None

**Returns:** `void`

**Example:**
```dart
// Before showing form
authController.clearError();
```

---

## Observable Properties

### isLoading

Reactive boolean indicating loading state.

```dart
final RxBool isLoading = false.obs;
```

**Usage:**
```dart
Obx(() => authController.isLoading.value
    ? CircularProgressIndicator()
    : LoginButton())
```

---

### currentUser

Reactive user object from Firebase Auth.

```dart
final Rx<User?> currentUser = Rx<User?>(null);
```

**Usage:**
```dart
Obx(() {
  final user = authController.currentUser.value;
  if (user != null) {
    return Text('Logged in as: ${user.email}');
  }
  return Text('Not logged in');
})
```

---

### errorMessage

Reactive string containing the last error message.

```dart
final RxString errorMessage = ''.obs;
```

**Usage:**
```dart
Obx(() {
  if (authController.errorMessage.value.isNotEmpty) {
    return Text(
      authController.errorMessage.value,
      style: TextStyle(color: Colors.red),
    );
  }
  return SizedBox.shrink();
})
```

---

## Error Codes & Messages

### Login Errors:
- `user-not-found`: "No user found with this email."
- `wrong-password`: "Incorrect password."
- `invalid-email`: "Invalid email address."
- `user-disabled`: "This account has been disabled."
- `invalid-credential`: "Invalid email or password."
- `auth-state-error`: "Authentication state error. Please try again."

### Registration Errors:
- `weak-password`: "The password provided is too weak."
- `email-already-in-use`: "The account already exists for that email."
- `invalid-email`: "Invalid email address."
- `operation-not-allowed`: "Email/password accounts are not enabled."

### Password Reset Errors:
- `user-not-found`: "No user found with this email."
- `invalid-email`: "Invalid email address."

---

## Complete Examples

### Login Screen Example:

```dart
class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authController = Get.find<AuthController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: passwordController, obscureText: true),
          
          Obx(() => authController.isLoading.value
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    final success = await authController.login(
                      email: emailController.text,
                      password: passwordController.text,
                      context: context,
                    );
                    
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authController.errorMessage.value),
                        ),
                      );
                    }
                  },
                  child: Text('Login'),
                ),
          ),
          
          // Show error if any
          Obx(() => authController.errorMessage.isNotEmpty
              ? Text(
                  authController.errorMessage.value,
                  style: TextStyle(color: Colors.red),
                )
              : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

### Check User Type Example:

```dart
class DashboardScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authController.isNGOUser(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final isNGO = snapshot.data!;
          return isNGO ? NGODashboard() : DonorDashboard();
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### User Profile Example:

```dart
class ProfileScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: authController.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!;
          return Column(
            children: [
              Text('Name: ${userData['name']}'),
              Text('Email: ${userData['email']}'),
              Text('Phone: ${userData['phone']}'),
              Text('Address: ${userData['address']}'),
              ElevatedButton(
                onPressed: () async {
                  await authController.logout();
                  Get.offAll(() => LoginScreen());
                },
                child: Text('Logout'),
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

---

## Best Practices

1. **Always check success status:**
   ```dart
   final success = await authController.login(...);
   if (!success) {
     // Handle error
   }
   ```

2. **Use Obx for reactive updates:**
   ```dart
   Obx(() => authController.isLoading.value
       ? Loader()
       : Button())
   ```

3. **Clear errors before new operations:**
   ```dart
   authController.clearError();
   await authController.login(...);
   ```

4. **Check context.mounted before navigation:**
   ```dart
   if (success && context.mounted) {
     Navigator.push(...);
   }
   ```

5. **Handle null returns from helper methods:**
   ```dart
   final userId = authController.getCurrentUserId();
   if (userId != null) {
     // Use userId
   }
   ```

---

## Testing

### Mock AuthController for Testing:

```dart
class MockAuthController extends GetxController implements AuthController {
  @override
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    // Mock implementation
    return email == 'test@test.com';
  }
  
  // ... other mocked methods
}
```

### Use in Tests:

```dart
testWidgets('Login button test', (tester) async {
  Get.put<AuthController>(MockAuthController());
  
  await tester.pumpWidget(MyApp());
  // ... test code
});
```

---

**Last Updated**: October 14, 2025  
**Version**: 1.0.0  
**Status**: Production Ready

