import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koduge_kart/controller_bindings.dart';
import 'package:koduge_kart/firebase_options.dart';
import 'package:koduge_kart/screens/donor_home.dart';
import 'package:koduge_kart/screens/login.dart';
import 'package:koduge_kart/screens/ngo_home.dart';
import 'package:koduge_kart/utils/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //name: 'com.food_share_connect.app',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Koduge Kart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialBinding: ControllerBindings(), // Added initial binding
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xff121212),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          // If user is logged in, fetch their data
          if (snapshot.hasData && snapshot.data != null) {
            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('user')
                      .doc(snapshot.data!.uid)
                      .snapshots(),
              builder: (context, storeSnapshot) {
                // Show loading while fetching user data
                if (storeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xff121212),
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                // Check if user data exists
                if (storeSnapshot.hasData &&
                    storeSnapshot.data != null &&
                    storeSnapshot.data!.exists) {
                  final userData =
                      storeSnapshot.data!.data() as Map<String, dynamic>?;

                  // Ensure userData is not null and has userType
                  if (userData != null && userData.containsKey('userType')) {
                    LoggerService.info(
                      'User data loaded successfully for ${snapshot.data!.uid}',
                      'MAIN',
                    );

                    // Navigate based on user type
                    if (userData['userType'] == "UserType.ngo") {
                      return const NGOHome();
                    } else {
                      return const DonorHome();
                    }
                  } else {
                    // User data is incomplete, sign out and show login
                    LoggerService.warning(
                      'User data incomplete for ${snapshot.data!.uid}, signing out',
                      'MAIN',
                    );
                    FirebaseAuth.instance.signOut();
                    return const LoginPage();
                  }
                } else {
                  // User document doesn't exist, sign out
                  LoggerService.warning(
                    'User document not found for ${snapshot.data!.uid}, signing out',
                    'MAIN',
                  );
                  FirebaseAuth.instance.signOut();
                  return const LoginPage();
                }
              },
            );
          }

          // No user logged in, show login page
          return const LoginPage();
        },
      ),
    );
  }
}
