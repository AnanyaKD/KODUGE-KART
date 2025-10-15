import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/utils/matching_service.dart';

class NGORequestHistoryScreen extends StatefulWidget {
  const NGORequestHistoryScreen({super.key});

  @override
  State<NGORequestHistoryScreen> createState() => _NGORequestHistoryScreenState();
}

class _NGORequestHistoryScreenState extends State<NGORequestHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NGORequestHistory> allRequests = [];
  List<NGORequestHistory> activeRequests = [];
  List<NGORequestHistory> fulfilledRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequestHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequestHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final results = await Future.wait([
        MatchingService.getNGORequestHistory(user.uid),
        MatchingService.getNGOAcceptedRequests(user.uid),
        MatchingService.getNGOFulfilledRequests(user.uid),
      ]);

      setState(() {
        allRequests = results[0];
        activeRequests = results[1];
        fulfilledRequests = results[2];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading request history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequestHistory,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Requests'),
            Tab(text: 'Active'),
            Tab(text: 'Fulfilled'),
          ],
          labelColor: AppColors.textColor,
          unselectedLabelColor: AppColors.textColor.withOpacity(0.7),
          indicatorColor: AppColors.textColor,
        ),
      ),
      backgroundColor: AppColors.backgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(allRequests, 'No requests found'),
                _buildRequestList(activeRequests, 'No active requests'),
                _buildRequestList(fulfilledRequests, 'No fulfilled requests'),
              ],
            ),
    );
  }

  Widget _buildRequestList(List<NGORequestHistory> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequestHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
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
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(request.addedDate),
                  style: TextStyle(
                    color: Colors.grey[600],
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
            
            // Match information
            if (request.matchedDonorIds.isNotEmpty) ...[
              Text(
                'Matches Found: ${request.matchedDonorIds.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Donor information if accepted
            if (request.acceptedDonorId != null) ...[
              const Divider(),
              const Text(
                'Donor Information:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (request.donorEmail.isNotEmpty)
                Text('Email: ${request.donorEmail}'),
              if (request.donorPhone.isNotEmpty)
                Text('Phone: ${request.donorPhone}'),
              if (request.donorAddress.isNotEmpty)
                Text('Address: ${request.donorAddress}'),
              if (request.acceptedDate != null)
                Text(
                  'Accepted on: ${_formatDate(request.acceptedDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'matched':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'fulfilled':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
