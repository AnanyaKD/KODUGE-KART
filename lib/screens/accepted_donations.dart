import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_share_connect/utils/matching_service.dart';

class AcceptedDonations extends StatefulWidget {
  const AcceptedDonations({
    super.key,
  });

  @override
  _AcceptedDonationsState createState() => _AcceptedDonationsState();
}

class _AcceptedDonationsState extends State<AcceptedDonations> {
  List<AcceptedDonation> acceptedDonations = [];
  bool loading = true;
  bool isNGOUser = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptedDonations();
  }

  Future<void> _loadAcceptedDonations() async {
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
          donations = await MatchingService.getAcceptedDonations(currentUser.uid);
        } else {
          donations = await MatchingService.getDonorAcceptedDonations(currentUser.uid);
        }
        
        if (mounted) {
          setState(() {
            acceptedDonations = donations;
            isNGOUser = isNGO;
            loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading accepted donations: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _fulfillDonation(AcceptedDonation donation) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Fulfillment'),
        content: const Text(
          'Are you sure you want to mark this donation as fulfilled? '
          'This action confirms that you have received the donated items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Marking as fulfilled...'),
            ],
          ),
        ),
      );

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          bool success = await MatchingService.fulfillDonation(
            donation.requestId,
            currentUser.uid,
          );

          // Close loading dialog
          if (mounted) Navigator.of(context).pop();

          if (success) {
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation marked as fulfilled successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload the list
              _loadAcceptedDonations();
            }
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to mark donation as fulfilled. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accepted Donations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff2A9D8F), // Teal for elegance
        foregroundColor: Colors.white,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAcceptedDonations,
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
              : acceptedDonations.isEmpty
              ? const Center(
                child: Text(
                  "No accepted donations found",
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
                          isNGOUser ? "Your Accepted Donations:" : "Your Accepted Donations:",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isNGOUser 
                            ? "Donations you have accepted from donors"
                            : "Your donations that have been accepted by NGOs",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Accepted Donations List
                  Expanded(
                    child: ListView.builder(
                      itemCount: acceptedDonations.length,
                      itemBuilder: (context, index) {
                        var donation = acceptedDonations[index];

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
                                        "Accepted Donation",
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
                                          color: donation.isFulfilled ? Colors.green : Colors.orange,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          donation.isFulfilled ? 'Fulfilled' : 'Pending',
                                          style: const TextStyle(
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
                                          "Accepted: ${donation.acceptedDate.toDate().toString().split('.')[0]}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Add fulfill button for NGO users on non-fulfilled donations
                                  if (isNGOUser && !donation.isFulfilled) ...[
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _fulfillDonation(donation),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text(
                                          'Mark as Fulfilled',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
