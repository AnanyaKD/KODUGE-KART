import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:food_share_connect/constants/app_colors.dart';
import 'package:food_share_connect/models/ngo_model.dart';
import 'package:food_share_connect/utils/matching_service.dart';

class MatchedNGOPage extends StatefulWidget {
  final NGOModel ngoRequest;

  const MatchedNGOPage({super.key, required this.ngoRequest});

  @override
  _MatchedNGOPageState createState() => _MatchedNGOPageState();
}

class _MatchedNGOPageState extends State<MatchedNGOPage> {
  List<MatchedDonor> matchedDonors = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchMatchedDonors();
  }

  fetchMatchedDonors() async {
    setState(() {
      loading = true;
    });
    try {
      // Use the new matching service
      List<MatchedDonor> results = await MatchingService.matchDonorsWithNGO(widget.ngoRequest);
      
      setState(() {
        matchedDonors = results;
        loading = false;
      });

      print('Found ${results.length} matched donors');
    } catch (e) {
      print("Error fetching matched donors: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (popInvoked) {
        // Clear controller data
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Matched Donors',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xff2A9D8F), // Teal for elegance
          foregroundColor: Colors.white,
          elevation: 5,
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
                : matchedDonors.isEmpty
                ? const Center(
                  child: Text(
                    "No matched donors found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff555555),
                    ), // Subtle dark gray text
                  ),
                )
                : Column(
                  children: [
                    // Display NGO's request at the top
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
                          const Text(
                            "NGO's Request:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.ngoRequest.items
                                .map((item) => "${item['name']} (${item['quantity']} ${item['unit']})")
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Matched Donors List
                    Expanded(
                      child: ListView.builder(
                        itemCount: matchedDonors.length,
                        itemBuilder: (context, index) {
                          var match = matchedDonors[index];

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
                                    // Match Score
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Match Score:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "${(match.matchScore * 100).toStringAsFixed(1)}%",
                                            style: const TextStyle(
                                              color: Color(0xff264653),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // Matched Items with Fulfilled Quantities
                                    const Text(
                                      "Matched Items:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    ...match.matchedItems.entries.map((entry) {
                                      var itemData = entry.value as Map<String, dynamic>;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          "• ${entry.key}: ${itemData['fulfilled']} of ${itemData['requested']} ${itemData['unit'] ?? 'units'} (${(itemData['matchPercentage'] * 100).toStringAsFixed(1)}% match)",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      );
                                    }).toList(),

                                    const SizedBox(height: 10),

                                    // Donor Details
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
                                            match.email,
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
                                          match.phone,
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
                                            match.address,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Accept Button
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          // Accept the donation using the matching service
                                          bool success = await MatchingService.acceptDonation(
                                            widget.ngoRequest.ngoId,
                                            match.requestId,
                                          );

                                          if (success) {
                                            // Send notification
                                            final notificationData = {
                                              "body": "Your donation has been accepted by an NGO!",
                                              "data": {
                                                "ngoId": widget.ngoRequest.ngoId,
                                                "type": "acceptance",
                                              },
                                              "read": false,
                                              "recipientId": match.donorId,
                                              "senderId": widget.ngoRequest.ngoId,
                                              "timestamp": Timestamp.now(),
                                              "title": "Donation Accepted!",
                                            };

                                            await FirebaseFirestore.instance
                                                .collection('notifications')
                                                .add(notificationData);

                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Successfully accepted donation from ${match.donorId}!",
                                                  ),
                                                ),
                                              );
                                              
                                              // Refresh the list
                                              fetchMatchedDonors();
                                            }
                                          } else {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Failed to accept donation. Please try again."),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          print("Error accepting donation: $e");
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Error: $e"),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.contrastTextColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        "Accept",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
