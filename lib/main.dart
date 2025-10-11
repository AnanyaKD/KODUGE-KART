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
      // Changed from MaterialApp to GetMaterialApp
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
          if (snapshot.hasData && snapshot.data != null) {
            return StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection('user')
                      .doc(snapshot.data!.uid)
                      .snapshots(),
              builder: (context, storeSnapshot) {
                if (storeSnapshot.hasData && storeSnapshot.data != null) {
                  if (storeSnapshot.data!['userType'] == "UserType.ngo") {
                    return const NGOHome();
                  } else {
                    return const DonorHome();
                  }
                } else {
                  return const Scaffold(
                    backgroundColor: Color(0xff121212),
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
              },
            );
          }
          return const LoginPage();
        },
      ),
    );
  }
}
