import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_share_connect/constants/app_colors.dart';
import 'package:food_share_connect/utils/matching_service.dart';
import 'package:intl/intl.dart';

class AvailableDonations extends StatefulWidget {
  const AvailableDonations({super.key});

  @override
  _AvailableDonationsState createState() => _AvailableDonationsState();
}

class _AvailableDonationsState extends State<AvailableDonations> {
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
        radiusKm: 50.0,
        limit: 20,
      );

      setState(() {
        availableDonations = donations;
        loading = false;
      });

      print('Loaded ${donations.length} available donations');
    } catch (e) {
      print('Error loading available donations: $e');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Donations'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableDonations,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : availableDonations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No available donations found',
                        style: TextStyle(
                          fontSize: 18,
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
                      final donation = availableDonations[index];
                      return _buildDonationCard(donation);
                    },
                  ),
                ),
    );
  }

  Widget _buildDonationCard(DonationRequest donation) {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(donation.addedDate.toDate()),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (donation.distance != null)
                      Text(
                        '${donation.distance!.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Request ID
            Text(
              'Request ID: ${donation.requestId}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Items available
            const Text(
              'Items Available:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Items list
            ...donation.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${item['quantity']} ${item['unit'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            
            // Donor information
            const Divider(),
            const Text(
              'Donor Contact:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (donation.email.isNotEmpty)
              Text('Email: ${donation.email}'),
            if (donation.phone.isNotEmpty)
              Text('Phone: ${donation.phone}'),
            if (donation.address.isNotEmpty)
              Text('Address: ${donation.address}'),
            
            const SizedBox(height: 16),
            
            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptDonation(donation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept Donation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptDonation(DonationRequest donation) async {
    if (currentUserId == null) return;

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Donation'),
          content: const Text('Are you sure you want to accept this donation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textColor,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          },
        );

        bool success = await MatchingService.acceptDonation(
          currentUserId!,
          donation.requestId,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the list
          _loadAvailableDonations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept donation. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still open
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
