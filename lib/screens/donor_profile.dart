import 'package:koduge_kart/constants/app_colors.dart';
  import 'package:flutter/material.dart';
  import 'package:koduge_kart/utils/utility_methods.dart';
  import 'package:koduge_kart/screens/donor_history.dart';
  import 'package:koduge_kart/screens/accepted_donations.dart';
  import 'package:koduge_kart/screens/fulfilled_donations.dart';

class DonorProfile extends StatefulWidget {
  const DonorProfile({super.key});

  @override
  State<DonorProfile> createState() => _DonorProfileState();
}

class _DonorProfileState extends State<DonorProfile> {
  String currentTab = "FOOD"; // Tracks the selected tab

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
              onPressed: () => {},

              // UtilityMethods.onLogout(context),
              icon: const Icon(Icons.person_outlined),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.account_circle,
                color: AppColors.inputBoxColor,
                size: 200,
              ),
            ),
            Text(
              "Donor Dashboard",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  ProfileButton('History', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DonorHistoryScreen(),
                      ),
                    );
                  }),
                  ProfileButton('Accepted', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AcceptedDonations(),
                      ),
                    );
                  }),
                  ProfileButton('Fulfilled', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FulfilledDonations(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(child: Container()),
            GestureDetector(
              onTap: () => {UtilityMethods.onLogout(context)},
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget ProfileButton(title, onPressed) {
  return Row(
    children: [
      Expanded(
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.primaryColor.withOpacity(0.8),
            ),
            margin: EdgeInsets.only(bottom: 10),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
            child: Text(
              "$title",
              style: TextStyle(color: AppColors.textColor, fontSize: 18),
            ),
          ),
        ),
      ),
    ],
  );
}
