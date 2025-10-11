import 'package:cloud_firestore/cloud_firestore.dart';

class NGOModel {
  final String ngoId;
  final String requestId; // Unique request ID
  final List<Map<String, dynamic>> items; // Structured JSON format
  final Timestamp addeddate;
  List<String> matchedDonorIds; // Track matched donors
  String? acceptedDonorId; // Track which donor was accepted
  Timestamp? acceptedDate;

  NGOModel({
    required this.ngoId,
    required this.requestId,
    required this.items,
    required this.addeddate,
    this.matchedDonorIds = const [],
    this.acceptedDonorId,
    this.acceptedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'requestId': requestId,
      'items': items,
      'addeddate': addeddate,
      'matchedDonorIds': matchedDonorIds,
      'acceptedDonorId': acceptedDonorId,
      'acceptedDate': acceptedDate,
    };
  }

  factory NGOModel.fromMap(Map<String, dynamic> map) {
    return NGOModel(
      ngoId: map['ngoId'] ?? '',
      requestId: map['requestId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      addeddate: map['addeddate'] ?? Timestamp.now(),
      matchedDonorIds: List<String>.from(map['matchedDonorIds'] ?? []),
      acceptedDonorId: map['acceptedDonorId'],
      acceptedDate: map['acceptedDate'],
    );
  }
}
