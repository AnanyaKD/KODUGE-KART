import 'package:koduge_kart/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:koduge_kart/screens/available_donations.dart';
import 'package:koduge_kart/screens/ngo_pending_requests.dart';
import 'package:koduge_kart/screens/ngo_matched_requests.dart';
import 'package:koduge_kart/screens/accepted_donations.dart';
import 'package:koduge_kart/screens/fulfilled_donations.dart';
import 'package:koduge_kart/utils/utility_methods.dart';

class NGOProfile extends StatefulWidget {
  const NGOProfile({super.key});

  @override
  State<NGOProfile> createState() => _NGOProfileState();
}

class _NGOProfileState extends State<NGOProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            text: "KODUGE KART",
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        actions: [
          Text(
            "NGO",
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => UtilityMethods.onLogout(context),
            icon: const Icon(Icons.person_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    color: AppColors.inputBoxColor,
                    size: 120,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "NGO Dashboard",
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // First Row - Available and Pending
                  Row(
                    children: [
                      Expanded(
                        child: _profileButton('Available Donations', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AvailableDonations(),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _profileButton('Pending Requests', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NGOPendingRequests(),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Second Row - Matched and Accepted
                  Row(
                    children: [
                      Expanded(
                        child: _profileButton('Matched Requests', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NGOMatchedRequests(),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _profileButton('Accepted Donations', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcceptedDonations(),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Third Row - Fulfilled (full width)
                  _profileButton('Fulfilled Donations', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FulfilledDonations(),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Logout Button
                  GestureDetector(
                    onTap: () => UtilityMethods.onLogout(context),
                    child: Text(
                      'Log out',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton(String title, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.8),
          foregroundColor: AppColors.textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
