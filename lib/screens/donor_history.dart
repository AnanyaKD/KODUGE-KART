import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_share_connect/constants/app_colors.dart';
import 'package:food_share_connect/models/donor_model.dart';
import 'package:food_share_connect/utils/matching_service.dart';
import 'package:intl/intl.dart';

class DonorHistoryScreen extends StatefulWidget {
  const DonorHistoryScreen({super.key});

  @override
  State<DonorHistoryScreen> createState() => _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends State<DonorHistoryScreen> {
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Pending', 'Matched', 'Accepted', 'Fulfilled'];

  // Method to fetch NGO details from Firestore
  Future<Map<String, dynamic>?> fetchNGODetails(String ngoId) async {
    try {
      DocumentSnapshot ngoDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(ngoId)
          .get();
      
      if (ngoDoc.exists) {
        return ngoDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching NGO details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Update Matches',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Updating donation matches...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              try {
                // Import MatchingService first
                // await MatchingService.updateExistingDonationsWithMatches();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Donation matches updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating matches: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterOptions.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: selectedFilter == filter,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      selectedColor: AppColors.primaryColor.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.textColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Donations list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donorfood')
                  .where('donorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .orderBy('addeddate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No donation history found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start by making your first donation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter donations based on selected filter
                List<QueryDocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
                  if (selectedFilter == 'All') return true;
                  
                  DonorModel donation = DonorModel.fromMap(doc.data() as Map<String, dynamic>);
                  
                  switch (selectedFilter) {
                    case 'Pending':
                      return donation.matchedNgoIds.isEmpty && !donation.isfulfilled;
                    case 'Matched':
                      return donation.matchedNgoIds.isNotEmpty && donation.acceptedByNgoId == null;
                    case 'Accepted':
                      return donation.acceptedByNgoId != null && !donation.isfulfilled;
                    case 'Fulfilled':
                      return donation.isfulfilled;
                    default:
                      return true;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $selectedFilter donations found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    DonorModel donation = DonorModel.fromMap(
                      filteredDocs[index].data() as Map<String, dynamic>
                    );
                    
                    return DonationHistoryCard(
                      donation: donation,
                      documentId: filteredDocs[index].id,
                      fetchNGODetails: fetchNGODetails, // Pass the fetchNGODetails method
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DonationHistoryCard extends StatefulWidget {
  final DonorModel donation;
  final String documentId;
  final Future<Map<String, dynamic>?> Function(String) fetchNGODetails;

  const DonationHistoryCard({
    super.key,
    required this.donation,
    required this.documentId,
    required this.fetchNGODetails,
  });

  @override
  State<DonationHistoryCard> createState() => _DonationHistoryCardState();
}

class _DonationHistoryCardState extends State<DonationHistoryCard> {
  Map<String, dynamic>? ngoDetails;
  bool loadingNGODetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.donation.acceptedByNgoId != null) {
      _fetchNGODetails();
    }
  }

  Future<void> _fetchNGODetails() async {
    if (widget.donation.acceptedByNgoId == null) return;
    
    setState(() {
      loadingNGODetails = true;
    });

    try {
      Map<String, dynamic>? details = await widget.fetchNGODetails(widget.donation.acceptedByNgoId!);
      if (mounted) {
        setState(() {
          ngoDetails = details;
          loadingNGODetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loadingNGODetails = false;
        });
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  String _getStatusText() {
    if (widget.donation.isfulfilled) return 'Fulfilled';
    if (widget.donation.acceptedByNgoId != null) return 'Accepted';
    if (widget.donation.matchedNgoIds.isNotEmpty) return 'Matched';
    return 'Pending';
  }

  Color _getStatusColor() {
    if (widget.donation.isfulfilled) return Colors.green;
    if (widget.donation.acceptedByNgoId != null) return Colors.blue;
    if (widget.donation.matchedNgoIds.isNotEmpty) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (widget.donation.isfulfilled) return Icons.check_circle;
    if (widget.donation.acceptedByNgoId != null) return Icons.handshake;
    if (widget.donation.matchedNgoIds.isNotEmpty) return Icons.link;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(widget.donation.addeddate),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Request ID
            Row(
              children: [
                const Icon(Icons.tag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'ID: ${widget.donation.requestId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Items list
            const Text(
              'Items Donated:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            ...widget.donation.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item['name']} - ${item['quantity']} ${item['unit'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
            
            // Show matching info if available
            if (widget.donation.matchedNgoIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Matched with ${widget.donation.matchedNgoIds.length} NGO${widget.donation.matchedNgoIds.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Show acceptance info if accepted
            if (widget.donation.acceptedByNgoId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.donation.acceptedDate != null
                          ? 'Accepted on ${_formatDate(widget.donation.acceptedDate!)}'
                          : 'Accepted by NGO',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Show fulfillment info if fulfilled
            if (widget.donation.isfulfilled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.celebration, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text(
                    'Donation completed successfully!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // NGO Details Section
            if (widget.donation.acceptedByNgoId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>?>(
                future: widget.fetchNGODetails(widget.donation.acceptedByNgoId!),
                builder: (context, ngoSnapshot) {
                  if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    );
                  }
                  
                  if (ngoSnapshot.hasError || !ngoSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Error fetching NGO details',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  
                  var ngoData = ngoSnapshot.data!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepted by: ${ngoData['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${ngoData['phone'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${ngoData['address'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
