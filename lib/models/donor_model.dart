import 'package:cloud_firestore/cloud_firestore.dart';

class DonorModel {
  String donorId;
  String requestId; // Unique request ID
  List<Map<String, dynamic>> items; // Structured JSON format
  Timestamp addeddate;
  bool isfulfilled;
  List<String> matchedNgoIds; // Track matched NGOs
  String? acceptedByNgoId; // Track which NGO accepted
  Timestamp? acceptedDate;

  DonorModel({
    required this.donorId,
    required this.requestId,
    required this.items,
    required this.addeddate,
    this.isfulfilled = false,
    this.matchedNgoIds = const [],
    this.acceptedByNgoId,
    this.acceptedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'requestId': requestId,
      'items': items,
      'addeddate': addeddate,
      'isfulfilled': isfulfilled,
      'matchedNgoIds': matchedNgoIds,
      'acceptedByNgoId': acceptedByNgoId,
      'acceptedDate': acceptedDate,
    };
  }

  factory DonorModel.fromMap(Map<String, dynamic> map) {
    return DonorModel(
      donorId: map['donorId'] ?? '',
      requestId: map['requestId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      addeddate: map['addeddate'],
      isfulfilled: map['isfulfilled'] ?? false,
      matchedNgoIds: List<String>.from(map['matchedNgoIds'] ?? []),
      acceptedByNgoId: map['acceptedByNgoId'],
      acceptedDate: map['acceptedDate'],
    );
  }
}
