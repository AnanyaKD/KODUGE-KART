import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_share_connect/utils/matching_service.dart';

class FulfilledDonations extends StatefulWidget {
  const FulfilledDonations({
    super.key,
  });

  @override
  _FulfilledDonationsState createState() => _FulfilledDonationsState();
}

class _FulfilledDonationsState extends State<FulfilledDonations> {
  List<AcceptedDonation> fulfilledDonations = [];
  bool loading = true;
  bool isNGOUser = false;

  @override
  void initState() {
    super.initState();
    _loadFulfilledDonations();
  }

  Future<void> _loadFulfilledDonations() async {
    if (!mounted) return;
    
    setState(() {
      loading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Check if user is NGO or Donor
        bool isNGO = await MatchingService.isNGOUser(currentUser.uid);
        
        List<AcceptedDonation> donations;
        if (isNGO) {
          donations = await MatchingService.getFulfilledDonations(currentUser.uid);
        } else {
          donations = await MatchingService.getDonorFulfilledDonations(currentUser.uid);
        }
        
        if (mounted) {
          setState(() {
            fulfilledDonations = donations;
            isNGOUser = isNGO;
            loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading fulfilled donations: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fulfilled Donations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff2A9D8F), // Teal for elegance
        foregroundColor: Colors.white,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFulfilledDonations,
          ),
        ],
      ),
      backgroundColor: const Color(0xffF4F4F4), // Light gray background
      body:
          loading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xff2A9D8F),
                  ), // Matching teal color
                ),
              )
              : fulfilledDonations.isEmpty
              ? const Center(
                child: Text(
                  "No fulfilled donations found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff555555),
                  ), // Subtle dark gray text
                ),
              )
              : Column(
                children: [
                  // Header info
                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff264653),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNGOUser ? "Your Fulfilled Donations:" : "Your Fulfilled Donations:",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isNGOUser
                            ? "Donations that have been completed"
                            : "Your donations that have been successfully fulfilled by NGOs",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fulfilled Donations List
                  Expanded(
                    child: ListView.builder(
                      itemCount: fulfilledDonations.length,
                      itemBuilder: (context, index) {
                        var donation = fulfilledDonations[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff264653),
                                  Color(0xff2A9D8F),
                                ], // Classy teal gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Fulfilled Donation",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Completed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Donated Items
                                  const Text(
                                    "Donated Items:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ...donation.items.map<Widget>((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        "• ${item['name']}: ${item['quantity']} units",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 10),

                                  // Contact Details (NGO or Donor based on user type)
                                  Text(
                                    isNGOUser ? "Donor Details:" : "NGO Details:",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          donation.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        donation.phone,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          donation.address,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Completed: ${donation.acceptedDate.toDate().toString().split('.')[0]}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
