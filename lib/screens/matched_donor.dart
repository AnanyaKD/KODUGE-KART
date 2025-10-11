import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_share_connect/controllers/donation_controller.dart';
import 'package:food_share_connect/models/donor_model.dart';
import 'package:food_share_connect/utils/matching_service.dart';
import 'package:get/get.dart';

class MatchedDonorPage extends StatefulWidget {
  final DonorModel donorRequest;

  const MatchedDonorPage({super.key, required this.donorRequest});

  @override
  _MatchedDonorPageState createState() => _MatchedDonorPageState();
}

class _MatchedDonorPageState extends State<MatchedDonorPage> {
  List<MatchedNGO> matchedNGOs = [];
  bool loading = false;
  DonationController donationController = Get.find();

  @override
  void initState() {
    super.initState();
    fetchMatchedNGOs();
  }

  fetchMatchedNGOs() async {
    setState(() {
      loading = true;
    });
    try {
      // Use the new matching service
      List<MatchedNGO> results = await MatchingService.matchNGOsWithDonor(widget.donorRequest);
      
      setState(() {
        matchedNGOs = results;
        loading = false;
      });

      print('Found ${results.length} matched NGOs');
    } catch (e) {
      print("Error fetching matched NGOs: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (popInvoked) {
        donationController.ngoFoodMap.clear();
        donationController.donorFoodMap.clear();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Matched NGOs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xff2A9D8F), // Elegant teal color
          foregroundColor: Colors.white, // White text for better visibility
          elevation: 5,
        ),
        backgroundColor: const Color(
          0xffF4F4F4,
        ), // Light background for contrast
        body: Column(
          children: [
            // Donor Food Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Contributions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(
                            0xff264653,
                          ), // Dark teal for section title
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.donorRequest.items
                            .map((item) => "${item['name']} (${item['quantity']} ${item['unit']})")
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff555555), // Muted dark gray for items
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Matched NGOs",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff264653), // Dark teal for section title
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // NGO Matched Items Section
            Expanded(
              child:
                  loading
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xff2A9D8F),
                          ), // Matching teal color
                        ),
                      )
                      : matchedNGOs.isEmpty
                      ? const Center(
                        child: Text(
                          "No matched NGOs found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff555555), // Subtle dark gray text
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: matchedNGOs.length,
                        itemBuilder: (context, index) {
                          var match = matchedNGOs[index];

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
                                    Color(
                                      0xffE9F5F2,
                                    ), // Light teal for contrast
                                    Color(0xffFFFFFF), // White
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Match Score
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Match Score:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff264653),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xff2A9D8F),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "${(match.matchScore * 100).toStringAsFixed(1)}%",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // Matched Items
                                    const Text(
                                      "Matched Items:",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff2A9D8F), // Teal for emphasis
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...match.matchedItems.entries.map((entry) {
                                      var itemData = entry.value as Map<String, dynamic>;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          "• ${entry.key}: ${itemData['fulfilled']} of ${itemData['requested']} ${itemData['unit'] ?? 'units'} (${(itemData['matchPercentage'] * 100).toStringAsFixed(1)}% match)",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(
                                      color: Color(0xff264653),
                                      thickness: 1.0,
                                      height: 20,
                                    ),

                                    // NGO Details
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.email,
                                          color: Color(0xff555555),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            match.email,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff555555),
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
                                          color: Color(0xff555555),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          match.phone,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff555555),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xff555555),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            match.address,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff555555),
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
      ),
    );
  }
}
