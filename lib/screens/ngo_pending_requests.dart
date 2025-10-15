import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/utils/matching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NGOPendingRequests extends StatefulWidget {
  const NGOPendingRequests({super.key});

  @override
  _NGOPendingRequestsState createState() => _NGOPendingRequestsState();
}

class _NGOPendingRequestsState extends State<NGOPendingRequests> {
  List<NGORequestHistory> pendingRequests = [];
  bool loading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    if (currentUserId == null) return;

    setState(() {
      loading = true;
    });

    try {
      List<NGORequestHistory> requests = await MatchingService.getNGOAcceptedRequests(currentUserId!);
      
      setState(() {
        pendingRequests = requests;
        loading = false;
      });
    } catch (e) {
      print('Error loading pending requests: $e');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : pendingRequests.isEmpty
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
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                ),
    );
  }

  Widget _buildRequestCard(NGORequestHistory request) {
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
            // Header with status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(request.addedDate),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Request ID
            Text(
              'Request ID: ${request.requestId}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Items requested
            const Text(
              'Items Requested:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Items list
            ...request.items.map((item) => Padding(
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
            
            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Waiting for donors to respond to your request',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
