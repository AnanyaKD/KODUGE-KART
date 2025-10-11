import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_share_connect/constants/app_colors.dart';
import 'package:food_share_connect/utils/matching_service.dart';
import 'package:intl/intl.dart';

class PendingDonations extends StatefulWidget {
  const PendingDonations({super.key});

  @override
  _PendingDonationsState createState() => _PendingDonationsState();
}

class _PendingDonationsState extends State<PendingDonations> {
  List<DonationRequest> availableDonations = [];
  bool loading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadAvailableDonations();
  }

  Future<void> _loadAvailableDonations() async {
    setState(() {
      loading = true;
    });

    try {
      print('Loading available donations for NGO: $currentUserId');
      
      // Get current NGO's location for nearby search
      DocumentSnapshot ngoProfile = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserId)
          .get();

      double? latitude, longitude;
      if (ngoProfile.exists) {
        Map<String, dynamic> ngoData = ngoProfile.data() as Map<String, dynamic>;
        latitude = ngoData['latitude']?.toDouble();
        longitude = ngoData['longitude']?.toDouble();
      }

      List<DonationRequest> donations = await MatchingService.getAvailableDonations(
        ngoId: currentUserId,
        latitude: latitude,
        longitude: longitude,
        radiusKm: 50.0, // 50km radius
        limit: 100,
      );

      print('Loaded ${donations.length} available donations');

      setState(() {
        availableDonations = donations;
        loading = false;
      });
    } catch (e) {
      print('Error loading available donations: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _acceptDonation(DonationRequest donation) async {
    try {
      print('Attempting to accept donation: ${donation.requestId}');
      bool success = await MatchingService.acceptDonation(
        currentUserId!,
        donation.requestId,
      );

      if (success) {
        print('Donation accepted successfully: ${donation.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Add a small delay to ensure Firestore updates are propagated
        await Future.delayed(const Duration(milliseconds: 500));
        _loadAvailableDonations(); // Refresh the list
      } else {
        print('Failed to accept donation: ${donation.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept donation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error accepting donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Donations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableDonations,
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : availableDonations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No donations available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for new donations!',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAvailableDonations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableDonations.length,
                    itemBuilder: (context, index) {
                      DonationRequest donation = availableDonations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with date and distance
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(donation.addedDate),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (donation.distance != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${donation.distance!.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Items
                              const Text(
                                'Available Items:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: donation.items.map((item) {
                                  return Chip(
                                    label: Text(
                                      '${item['name']} (${item['quantity']})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),

                              // Donor contact info
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          donation.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (donation.phone.isNotEmpty)
                                          Text(
                                            donation.phone,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Address
                              if (donation.address.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        donation.address,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Accept button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _acceptDonation(donation),
                                  icon: const Icon(Icons.handshake),
                                  label: const Text('Accept Donation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: AppColors.textColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}