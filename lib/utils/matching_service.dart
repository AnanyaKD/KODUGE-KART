import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koduge_kart/models/donor_model.dart';
import 'dart:math' as math;

import 'package:koduge_kart/models/ngo_model.dart';

class MatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is NGO based on userType field
  static Future<bool> isNGOUser(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('user').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['userType'] == "UserType.ngo";
      }
      return false;
    } catch (e) {
      print('Error checking user type: $e');
      return false;
    }
  }

  // Generate unique request ID
  static String generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  // Match donors with NGOs based on quantity and availability
  static Future<List<MatchedDonor>> matchDonorsWithNGO(
    NGOModel ngoRequest,
  ) async {
    try {
      // Get all active donor requests
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('isfulfilled', isEqualTo: false)
              .get();

      List<MatchedDonor> matchedDonors = [];

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Skip if donor already accepted by another NGO
        if (donorRequest.acceptedByNgoId != null) continue;

        Map<String, dynamic> matchResult = calculateMatch(
          ngoRequest,
          donorRequest,
        );

        if (matchResult['matchScore'] > 0) {
          // Get donor details
          DocumentSnapshot donorDetails =
              await _firestore
                  .collection('user')
                  .doc(donorRequest.donorId)
                  .get();

          if (donorDetails.exists) {
            Map<String, dynamic> userData =
                donorDetails.data() as Map<String, dynamic>;

            matchedDonors.add(
              MatchedDonor(
                donorId: donorRequest.donorId,
                requestId: donorRequest.requestId,
                matchedItems: matchResult['matchedItems'],
                matchScore: matchResult['matchScore'],
                email: userData['email'] ?? '',
                phone: userData['phone'] ?? '',
                address: userData['address'] ?? '',
              ),
            );
          }
        }
      }

      // Sort by match score (highest first)
      matchedDonors.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return matchedDonors;
    } catch (e) {
      print('Error matching donors: $e');
      return [];
    }
  }

  // Match NGOs with donor based on quantity and availability
  static Future<List<MatchedNGO>> matchNGOsWithDonor(
    DonorModel donorRequest,
  ) async {
    try {
      // Get all active NGO requests
      QuerySnapshot ngoSnapshot = await _firestore.collection('ngofood').get();

      List<MatchedNGO> matchedNGOs = [];

      for (var doc in ngoSnapshot.docs) {
        NGOModel ngoRequest = NGOModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Skip if NGO already accepted by another donor
        if (ngoRequest.acceptedDonorId != null) continue;

        Map<String, dynamic> matchResult = calculateMatch(
          ngoRequest,
          donorRequest,
        );

        if (matchResult['matchScore'] > 0) {
          // Get NGO details
          DocumentSnapshot ngoDetails =
              await _firestore.collection('user').doc(ngoRequest.ngoId).get();

          if (ngoDetails.exists) {
            Map<String, dynamic> userData =
                ngoDetails.data() as Map<String, dynamic>;

            matchedNGOs.add(
              MatchedNGO(
                ngoId: ngoRequest.ngoId,
                requestId: ngoRequest.requestId,
                matchedItems: matchResult['matchedItems'],
                matchScore: matchResult['matchScore'],
                email: userData['email'] ?? '',
                phone: userData['phone'] ?? '',
                address: userData['address'] ?? '',
              ),
            );
          }
        }
      }

      // Sort by match score (highest first)
      matchedNGOs.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return matchedNGOs;
    } catch (e) {
      print('Error matching NGOs: $e');
      return [];
    }
  }

  // Calculate match between NGO request and donor contribution
  // Made public for testing purposes
  static Map<String, dynamic> calculateMatch(
    NGOModel ngoRequest,
    DonorModel donorRequest,
  ) {
    Map<String, dynamic> matchedItems = {};
    double totalMatchScore = 0.0;
    int totalRequestedItems = ngoRequest.items.length;
    int matchedItemCount = 0;

    // Create maps for easier lookup
    Map<String, int> ngoItems = {};
    Map<String, int> donorItems = {};

    for (var item in ngoRequest.items) {
      ngoItems[item['name'].toString().toUpperCase()] = item['quantity'] as int;
    }

    for (var item in donorRequest.items) {
      donorItems[item['name'].toString().toUpperCase()] =
          item['quantity'] as int;
    }

    // Check all requested items (both matched and unmatched)
    for (String ngoItemName in ngoItems.keys) {
      int ngoQuantity = ngoItems[ngoItemName]!;

      if (donorItems.containsKey(ngoItemName)) {
        // Item is available in donation
        int donorQuantity = donorItems[ngoItemName]!;

        // Calculate fulfilled quantity (minimum of requested and available)
        int fulfilledQuantity =
            ngoQuantity < donorQuantity ? ngoQuantity : donorQuantity;

        // Calculate match score (percentage of request fulfilled for this item)
        double itemMatchPercentage = fulfilledQuantity / ngoQuantity;

        matchedItems[ngoItemName] = {
          'requested': ngoQuantity,
          'available': donorQuantity,
          'fulfilled': fulfilledQuantity,
          'matchPercentage': itemMatchPercentage,
          'isMatched': true,
        };

        totalMatchScore += itemMatchPercentage;
        matchedItemCount++;
      } else {
        // Item is not available in donation - contributes 0 to score
        matchedItems[ngoItemName] = {
          'requested': ngoQuantity,
          'available': 0,
          'fulfilled': 0,
          'matchPercentage': 0.0,
          'isMatched': false,
        };

        // Add 0 to total score (explicitly showing missing items penalize the score)
        totalMatchScore += 0.0;
      }
    }

    // Calculate overall match score considering ALL requested items
    // This ensures donations missing some items get lower scores
    double overallMatchScore =
        totalRequestedItems > 0 ? totalMatchScore / totalRequestedItems : 0.0;

    // Calculate completeness bonus: donations that have more of the requested items get a slight bonus
    double completenessRatio =
        totalRequestedItems > 0 ? matchedItemCount / totalRequestedItems : 0.0;

    // Apply completeness factor to encourage donations that fulfill more item types
    // Donations with all requested items get full score, partial donations get reduced score
    double finalScore = overallMatchScore * (0.5 + 0.5 * completenessRatio);

    return {
      'matchedItems': matchedItems,
      'matchScore': finalScore,
      'totalRequestedItems': totalRequestedItems,
      'matchedItemCount': matchedItemCount,
      'completenessRatio': completenessRatio,
      'rawScore': overallMatchScore,
    };
  }

  // Accept donation by NGO
  static Future<bool> acceptDonation(
    String ngoId,
    String donorRequestId,
  ) async {
    try {
      // Use a transaction to ensure atomicity
      return await _firestore.runTransaction<bool>((transaction) async {
        // First, find the donor document by requestId
        QuerySnapshot donorSnapshot =
            await _firestore
                .collection('donorfood')
                .where('requestId', isEqualTo: donorRequestId)
                .where('isfulfilled', isEqualTo: false)
                .limit(1)
                .get();

        if (donorSnapshot.docs.isEmpty) {
          print(
            'Donor request not found or already fulfilled for requestId: $donorRequestId',
          );
          return false;
        }

        DocumentSnapshot donorDoc = donorSnapshot.docs.first;
        Map<String, dynamic> donorData =
            donorDoc.data() as Map<String, dynamic>;

        // Check if already accepted by another NGO
        if (donorData['acceptedByNgoId'] != null) {
          print(
            'Donation already accepted by another NGO: ${donorData['acceptedByNgoId']}',
          );
          return false;
        }

        String donorDocumentId = donorDoc.id;

        // Update donor request - DON'T mark as fulfilled yet, that's a separate step
        transaction.update(
          _firestore.collection('donorfood').doc(donorDocumentId),
          {
            'acceptedByNgoId': ngoId,
            'acceptedDate': Timestamp.now(),
            // isfulfilled remains false until manually marked as fulfilled
          },
        );

        // Find the NGO document by ngoId field and update it
        QuerySnapshot ngoSnapshot =
            await _firestore
                .collection('ngofood')
                .where('ngoId', isEqualTo: ngoId)
                .limit(1)
                .get();

        if (ngoSnapshot.docs.isNotEmpty) {
          String ngoDocumentId = ngoSnapshot.docs.first.id;
          transaction.update(
            _firestore.collection('ngofood').doc(ngoDocumentId),
            {
              'acceptedDonorId': donorRequestId,
              'acceptedDate': Timestamp.now(),
            },
          );
        } else {
          print('NGO document not found for ngoId: $ngoId');
          return false;
        }

        print(
          'Successfully updated donor request $donorRequestId with acceptedByNgoId: $ngoId',
        );
        return true;
      });
    } catch (e) {
      print('Error accepting donation: $e');
      return false;
    }
  }

  // Mark donation as fulfilled by NGO
  static Future<bool> fulfillDonation(
    String donorRequestId,
    String ngoId,
  ) async {
    try {
      // First, find the donor document by requestId and verify it's accepted by this NGO
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('requestId', isEqualTo: donorRequestId)
              .where('acceptedByNgoId', isEqualTo: ngoId)
              .where('isfulfilled', isEqualTo: false)
              .limit(1)
              .get();

      if (donorSnapshot.docs.isEmpty) {
        print(
          'Donor request not found, not accepted by this NGO, or already fulfilled for requestId: $donorRequestId',
        );
        return false;
      }

      String donorDocumentId = donorSnapshot.docs.first.id;

      // Update donor request to mark as fulfilled
      await _firestore.collection('donorfood').doc(donorDocumentId).update({
        'isfulfilled': true,
        'fulfilledDate': Timestamp.now(),
      });

      print('Successfully marked donation as fulfilled: $donorRequestId');
      return true;
    } catch (e) {
      print('Error fulfilling donation: $e');
      return false;
    }
  }

  // Get all available donation requests for NGOs (nearby and latest)
  static Future<List<DonationRequest>> getAvailableDonations({
    String? ngoId,
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    int limit = 50,
  }) async {
    try {
      // Get all unfulfilled donor requests
      // Note: We filter out accepted donations in the code rather than query
      // to handle both null and missing acceptedByNgoId fields properly
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('isfulfilled', isEqualTo: false)
              .orderBy('addeddate', descending: true)
              .limit(limit * 2) // Get more to account for filtering
              .get();

      List<DonationRequest> donations = [];
      int filteredCount = 0;

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Skip donations that have been accepted by any NGO
        if (donorRequest.acceptedByNgoId != null) {
          filteredCount++;
          print(
            'Filtering out donation ${donorRequest.requestId} - already accepted by ${donorRequest.acceptedByNgoId}',
          );
          continue;
        }

        // Get donor details
        DocumentSnapshot donorDetails =
            await _firestore.collection('user').doc(donorRequest.donorId).get();

        if (donorDetails.exists) {
          Map<String, dynamic> userData =
              donorDetails.data() as Map<String, dynamic>;

          // Calculate distance if coordinates are provided
          double? distance;
          if (latitude != null &&
              longitude != null &&
              userData['latitude'] != null &&
              userData['longitude'] != null) {
            distance = _calculateDistance(
              latitude,
              longitude,
              userData['latitude'],
              userData['longitude'],
            );

            // Skip if outside radius
            if (distance > radiusKm) continue;
          }

          donations.add(
            DonationRequest(
              documentId: doc.id,
              donorId: donorRequest.donorId,
              requestId: donorRequest.requestId,
              items: donorRequest.items,
              addedDate: donorRequest.addeddate,
              email: userData['email'] ?? '',
              phone: userData['phone'] ?? '',
              address: userData['address'] ?? '',
              latitude: userData['latitude']?.toDouble(),
              longitude: userData['longitude']?.toDouble(),
              distance: distance,
            ),
          );

          // Stop if we've reached the desired limit
          if (donations.length >= limit) {
            break;
          }
        }
      }

      // Sort by date (newest first), then by distance if available
      donations.sort((a, b) {
        if (a.distance != null && b.distance != null) {
          int dateComparison = b.addedDate.compareTo(a.addedDate);
          if (dateComparison == 0) {
            return a.distance!.compareTo(b.distance!);
          }
          return dateComparison;
        }
        return b.addedDate.compareTo(a.addedDate);
      });

      print(
        'getAvailableDonations: Found ${donations.length} available donations (filtered out $filteredCount accepted donations)',
      );

      return donations;
    } catch (e) {
      print('Error getting available donations: $e');
      return [];
    }
  }

  // Get donation requests that match NGO's specific needs
  static Future<List<MatchedDonationRequest>> getMatchedDonations(
    NGOModel ngoRequest,
  ) async {
    try {
      List<DonationRequest> availableDonations = await getAvailableDonations();
      List<MatchedDonationRequest> matchedDonations = [];

      for (var donation in availableDonations) {
        // Create a temporary DonorModel for matching calculation
        DonorModel donorModel = DonorModel(
          donorId: donation.donorId,
          requestId: donation.requestId,
          items: donation.items.cast<Map<String, dynamic>>(),
          addeddate: donation.addedDate,
          matchedNgoIds: [],
          acceptedByNgoId: null,
          isfulfilled: false,
        );

        Map<String, dynamic> matchResult = calculateMatch(
          ngoRequest,
          donorModel,
        );

        if (matchResult['matchScore'] > 0) {
          matchedDonations.add(
            MatchedDonationRequest(
              donation: donation,
              matchedItems: matchResult['matchedItems'],
              matchScore: matchResult['matchScore'],
            ),
          );
        }
      }

      // Sort by match score (highest first)
      matchedDonations.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return matchedDonations;
    } catch (e) {
      print('Error getting matched donations: $e');
      return [];
    }
  }

  // Update existing NGO requests when new donations are added
  static Future<void> notifyNGOsOfNewDonation(DonorModel newDonation) async {
    try {
      print(
        'Starting to notify NGOs of new donation: ${newDonation.requestId}',
      );

      // Get all pending NGO requests
      QuerySnapshot ngoSnapshot =
          await _firestore
              .collection('ngofood')
              .where('acceptedDonorId', isEqualTo: null)
              .get();

      print('Found ${ngoSnapshot.docs.length} pending NGO requests');
      List<String> matchedNgoIds = [];

      for (var doc in ngoSnapshot.docs) {
        NGOModel ngoRequest = NGOModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        Map<String, dynamic> matchResult = calculateMatch(
          ngoRequest,
          newDonation,
        );

        if (matchResult['matchScore'] > 0) {
          print(
            'Match found with NGO ${ngoRequest.ngoId}, score: ${matchResult['matchScore']}',
          );

          // Update NGO request with new matched donor
          List<String> updatedMatchedDonors = List<String>.from(
            ngoRequest.matchedDonorIds,
          );
          if (!updatedMatchedDonors.contains(newDonation.donorId)) {
            updatedMatchedDonors.add(newDonation.donorId);

            await _firestore.collection('ngofood').doc(doc.id).update({
              'matchedDonorIds': updatedMatchedDonors,
            });

            // Track matched NGO ID for donor update
            matchedNgoIds.add(ngoRequest.ngoId);

            // Send notification to NGO
            await _sendMatchNotificationToNGO(
              ngoRequest.ngoId,
              newDonation,
              matchResult['matchScore'],
            );
          }
        }
      }

      // Update donor document with matched NGO IDs
      if (matchedNgoIds.isNotEmpty) {
        print(
          'Updating donor document with ${matchedNgoIds.length} matched NGO IDs',
        );

        QuerySnapshot donorSnapshot =
            await _firestore
                .collection('donorfood')
                .where('requestId', isEqualTo: newDonation.requestId)
                .where('donorId', isEqualTo: newDonation.donorId)
                .limit(1)
                .get();

        if (donorSnapshot.docs.isNotEmpty) {
          String donorDocumentId = donorSnapshot.docs.first.id;
          await _firestore.collection('donorfood').doc(donorDocumentId).update({
            'matchedNgoIds': matchedNgoIds,
          });
          print(
            'Successfully updated donor document with ${matchedNgoIds.length} matched NGO IDs',
          );
        } else {
          print('ERROR: Could not find donor document to update with matches');
        }
      } else {
        print('No matches found for this donation');
      }
    } catch (e) {
      print('Error notifying NGOs of new donation: $e');
    }
  }

  // Send notification to NGO about new matching donation
  static Future<void> _sendMatchNotificationToNGO(
    String ngoId,
    DonorModel donation,
    double matchScore,
  ) async {
    try {
      final notificationData = {
        "body":
            "New donation available with ${(matchScore * 100).toStringAsFixed(1)}% match!",
        "data": {
          "donorId": donation.donorId,
          "requestId": donation.requestId,
          "type": "new_match",
        },
        "read": false,
        "recipientId": ngoId,
        "senderId": donation.donorId,
        "timestamp": Timestamp.now(),
        "title": "New Matching Donation Available!",
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Get accepted donations for an NGO
  static Future<List<AcceptedDonation>> getAcceptedDonations(
    String ngoId,
  ) async {
    try {
      // Get all donor requests accepted by this NGO that are not yet fulfilled
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('acceptedByNgoId', isEqualTo: ngoId)
              .where('isfulfilled', isEqualTo: false)
              .get();

      List<AcceptedDonation> acceptedDonations = [];

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Get donor details
        DocumentSnapshot donorDetails =
            await _firestore.collection('user').doc(donorRequest.donorId).get();

        if (donorDetails.exists) {
          Map<String, dynamic> userData =
              donorDetails.data() as Map<String, dynamic>;
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          acceptedDonations.add(
            AcceptedDonation(
              documentId: doc.id,
              donorId: donorRequest.donorId,
              requestId: donorRequest.requestId,
              items: donorRequest.items,
              acceptedDate:
                  docData['acceptedDate'] as Timestamp? ?? Timestamp.now(),
              isFulfilled: donorRequest.isfulfilled,
              email: userData['email'] ?? '',
              phone: userData['phone'] ?? '',
              address: userData['address'] ?? '',
            ),
          );
        }
      }

      // Sort by accepted date (newest first)
      acceptedDonations.sort(
        (a, b) => b.acceptedDate.compareTo(a.acceptedDate),
      );

      return acceptedDonations;
    } catch (e) {
      print('Error getting accepted donations: $e');
      return [];
    }
  }

  // Get fulfilled donations for an NGO
  static Future<List<AcceptedDonation>> getFulfilledDonations(
    String ngoId,
  ) async {
    try {
      // Get all donor requests fulfilled by this NGO
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('acceptedByNgoId', isEqualTo: ngoId)
              .where('isfulfilled', isEqualTo: true)
              .get();

      List<AcceptedDonation> fulfilledDonations = [];

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Get donor details
        DocumentSnapshot donorDetails =
            await _firestore.collection('user').doc(donorRequest.donorId).get();

        if (donorDetails.exists) {
          Map<String, dynamic> userData =
              donorDetails.data() as Map<String, dynamic>;
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          fulfilledDonations.add(
            AcceptedDonation(
              documentId: doc.id,
              donorId: donorRequest.donorId,
              requestId: donorRequest.requestId,
              items: donorRequest.items,
              acceptedDate:
                  docData['acceptedDate'] as Timestamp? ?? Timestamp.now(),
              isFulfilled: donorRequest.isfulfilled,
              email: userData['email'] ?? '',
              phone: userData['phone'] ?? '',
              address: userData['address'] ?? '',
            ),
          );
        }
      }

      // Sort by accepted date (newest first)
      fulfilledDonations.sort(
        (a, b) => b.acceptedDate.compareTo(a.acceptedDate),
      );

      return fulfilledDonations;
    } catch (e) {
      print('Error getting fulfilled donations: $e');
      return [];
    }
  }

  // Get accepted donations from donor's perspective
  static Future<List<AcceptedDonation>> getDonorAcceptedDonations(
    String donorId,
  ) async {
    try {
      // Get all donor requests that have been accepted by NGOs but not yet fulfilled
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('donorId', isEqualTo: donorId)
              .where('acceptedByNgoId', isNotEqualTo: null)
              .where('isfulfilled', isEqualTo: false)
              .get();

      List<AcceptedDonation> acceptedDonations = [];

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Get NGO details instead of donor details
        DocumentSnapshot ngoDetails =
            await _firestore
                .collection('user')
                .doc(donorRequest.acceptedByNgoId!)
                .get();

        if (ngoDetails.exists) {
          Map<String, dynamic> userData =
              ngoDetails.data() as Map<String, dynamic>;
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          acceptedDonations.add(
            AcceptedDonation(
              documentId: doc.id,
              donorId: donorRequest.donorId,
              requestId: donorRequest.requestId,
              items: donorRequest.items,
              acceptedDate:
                  docData['acceptedDate'] as Timestamp? ?? Timestamp.now(),
              isFulfilled: donorRequest.isfulfilled,
              email: userData['email'] ?? '',
              phone: userData['phone'] ?? '',
              address: userData['address'] ?? '',
              // For donor perspective, we show NGO info instead
              acceptedByNgoId: donorRequest.acceptedByNgoId,
            ),
          );
        }
      }

      // Sort by accepted date (newest first)
      acceptedDonations.sort(
        (a, b) => b.acceptedDate.compareTo(a.acceptedDate),
      );

      return acceptedDonations;
    } catch (e) {
      print('Error getting donor accepted donations: $e');
      return [];
    }
  }

  // Get fulfilled donations from donor's perspective
  static Future<List<AcceptedDonation>> getDonorFulfilledDonations(
    String donorId,
  ) async {
    try {
      // Get all donor requests that have been fulfilled
      QuerySnapshot donorSnapshot =
          await _firestore
              .collection('donorfood')
              .where('donorId', isEqualTo: donorId)
              .where('isfulfilled', isEqualTo: true)
              .get();

      List<AcceptedDonation> fulfilledDonations = [];

      for (var doc in donorSnapshot.docs) {
        DonorModel donorRequest = DonorModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Get NGO details who fulfilled the donation
        DocumentSnapshot ngoDetails =
            await _firestore
                .collection('user')
                .doc(donorRequest.acceptedByNgoId!)
                .get();

        if (ngoDetails.exists) {
          Map<String, dynamic> userData =
              ngoDetails.data() as Map<String, dynamic>;
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          fulfilledDonations.add(
            AcceptedDonation(
              documentId: doc.id,
              donorId: donorRequest.donorId,
              requestId: donorRequest.requestId,
              items: donorRequest.items,
              acceptedDate:
                  docData['acceptedDate'] as Timestamp? ?? Timestamp.now(),
              isFulfilled: donorRequest.isfulfilled,
              email: userData['email'] ?? '',
              phone: userData['phone'] ?? '',
              address: userData['address'] ?? '',
              // For donor perspective, we show NGO info instead
              acceptedByNgoId: donorRequest.acceptedByNgoId,
            ),
          );
        }
      }

      // Sort by accepted date (newest first)
      fulfilledDonations.sort(
        (a, b) => b.acceptedDate.compareTo(a.acceptedDate),
      );

      return fulfilledDonations;
    } catch (e) {
      print('Error getting donor fulfilled donations: $e');
      return [];
    }
  }

  // Get NGO request history
  static Future<List<NGORequestHistory>> getNGORequestHistory(
    String ngoId,
  ) async {
    try {
      // Get all requests made by this NGO
      QuerySnapshot ngoSnapshot =
          await _firestore
              .collection('ngofood')
              .where('ngoId', isEqualTo: ngoId)
              .orderBy('addeddate', descending: true)
              .get();

      List<NGORequestHistory> requestHistory = [];

      for (var doc in ngoSnapshot.docs) {
        NGOModel ngoRequest = NGOModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Get matched donor details if accepted
        String? donorEmail;
        String? donorPhone;
        String? donorAddress;

        if (ngoRequest.acceptedDonorId != null) {
          // Find the donor request to get donor details
          QuerySnapshot donorSnapshot =
              await _firestore
                  .collection('donorfood')
                  .where('requestId', isEqualTo: ngoRequest.acceptedDonorId)
                  .limit(1)
                  .get();

          if (donorSnapshot.docs.isNotEmpty) {
            DonorModel donorRequest = DonorModel.fromMap(
              donorSnapshot.docs.first.data() as Map<String, dynamic>,
            );

            // Get donor user details
            DocumentSnapshot donorDetails =
                await _firestore
                    .collection('user')
                    .doc(donorRequest.donorId)
                    .get();

            if (donorDetails.exists) {
              Map<String, dynamic> userData =
                  donorDetails.data() as Map<String, dynamic>;
              donorEmail = userData['email'] ?? '';
              donorPhone = userData['phone'] ?? '';
              donorAddress = userData['address'] ?? '';
            }
          }
        }

        requestHistory.add(
          NGORequestHistory(
            documentId: doc.id,
            requestId: ngoRequest.requestId,
            items: ngoRequest.items,
            addedDate: ngoRequest.addeddate,
            matchedDonorIds: ngoRequest.matchedDonorIds,
            acceptedDonorId: ngoRequest.acceptedDonorId,
            acceptedDate: ngoRequest.acceptedDate,
            donorEmail: donorEmail ?? '',
            donorPhone: donorPhone ?? '',
            donorAddress: donorAddress ?? '',
            status: getNGORequestStatus(ngoRequest),
          ),
        );
      }

      return requestHistory;
    } catch (e) {
      print('Error getting NGO request history: $e');
      return [];
    }
  }

  // Get NGO active/pending requests
  static Future<List<NGORequestHistory>> getNGOAcceptedRequests(
    String ngoId,
  ) async {
    try {
      // Get pending requests (not accepted by any donor)
      QuerySnapshot ngoSnapshot =
          await _firestore
              .collection('ngofood')
              .where('ngoId', isEqualTo: ngoId)
              .where('acceptedDonorId', isEqualTo: null)
              .orderBy('addeddate', descending: true)
              .get();

      List<NGORequestHistory> activeRequests = [];

      for (var doc in ngoSnapshot.docs) {
        NGOModel ngoRequest = NGOModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        activeRequests.add(
          NGORequestHistory(
            documentId: doc.id,
            requestId: ngoRequest.requestId,
            items: ngoRequest.items,
            addedDate: ngoRequest.addeddate,
            matchedDonorIds: ngoRequest.matchedDonorIds,
            acceptedDonorId: ngoRequest.acceptedDonorId,
            acceptedDate: ngoRequest.acceptedDate,
            donorEmail: '',
            donorPhone: '',
            donorAddress: '',
            status: 'Pending',
          ),
        );
      }

      return activeRequests;
    } catch (e) {
      print('Error getting NGO active requests: $e');
      return [];
    }
  }

  // Get NGO fulfilled requests
  static Future<List<NGORequestHistory>> getNGOFulfilledRequests(
    String ngoId,
  ) async {
    try {
      // Get requests that have been accepted and fulfilled
      QuerySnapshot ngoSnapshot =
          await _firestore
              .collection('ngofood')
              .where('ngoId', isEqualTo: ngoId)
              .where('acceptedDonorId', isNotEqualTo: null)
              .orderBy('addeddate', descending: true)
              .get();

      List<NGORequestHistory> fulfilledRequests = [];

      for (var doc in ngoSnapshot.docs) {
        NGOModel ngoRequest = NGOModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Check if the corresponding donor request is fulfilled
        bool isFulfilled = false;
        if (ngoRequest.acceptedDonorId != null) {
          QuerySnapshot donorSnapshot =
              await _firestore
                  .collection('donorfood')
                  .where('requestId', isEqualTo: ngoRequest.acceptedDonorId)
                  .where('isfulfilled', isEqualTo: true)
                  .limit(1)
                  .get();

          isFulfilled = donorSnapshot.docs.isNotEmpty;
        }

        if (isFulfilled) {
          // Get donor details
          QuerySnapshot donorSnapshot =
              await _firestore
                  .collection('donorfood')
                  .where('requestId', isEqualTo: ngoRequest.acceptedDonorId)
                  .limit(1)
                  .get();

          String? donorEmail;
          String? donorPhone;
          String? donorAddress;

          if (donorSnapshot.docs.isNotEmpty) {
            DonorModel donorRequest = DonorModel.fromMap(
              donorSnapshot.docs.first.data() as Map<String, dynamic>,
            );

            DocumentSnapshot donorDetails =
                await _firestore
                    .collection('user')
                    .doc(donorRequest.donorId)
                    .get();

            if (donorDetails.exists) {
              Map<String, dynamic> userData =
                  donorDetails.data() as Map<String, dynamic>;
              donorEmail = userData['email'] ?? '';
              donorPhone = userData['phone'] ?? '';
              donorAddress = userData['address'] ?? '';
            }
          }

          fulfilledRequests.add(
            NGORequestHistory(
              documentId: doc.id,
              requestId: ngoRequest.requestId,
              items: ngoRequest.items,
              addedDate: ngoRequest.addeddate,
              matchedDonorIds: ngoRequest.matchedDonorIds,
              acceptedDonorId: ngoRequest.acceptedDonorId,
              acceptedDate: ngoRequest.acceptedDate,
              donorEmail: donorEmail ?? '',
              donorPhone: donorPhone ?? '',
              donorAddress: donorAddress ?? '',
              status: 'Fulfilled',
            ),
          );
        }
      }

      return fulfilledRequests;
    } catch (e) {
      print('Error getting NGO fulfilled requests: $e');
      return [];
    }
  }

  // Helper method to determine NGO request status - public for testing
  static String getNGORequestStatus(NGOModel ngoRequest) {
    if (ngoRequest.acceptedDonorId == null) {
      return ngoRequest.matchedDonorIds.isNotEmpty ? 'Matched' : 'Pending';
    } else {
      return 'Accepted';
    }
  }

  // ...existing code...
}

// Data classes for matched results
class MatchedDonor {
  final String donorId;
  final String requestId;
  final Map<String, dynamic> matchedItems;
  final double matchScore;
  final String email;
  final String phone;
  final String address;

  MatchedDonor({
    required this.donorId,
    required this.requestId,
    required this.matchedItems,
    required this.matchScore,
    required this.email,
    required this.phone,
    required this.address,
  });
}

class MatchedNGO {
  final String ngoId;
  final String requestId;
  final Map<String, dynamic> matchedItems;
  final double matchScore;
  final String email;
  final String phone;
  final String address;

  MatchedNGO({
    required this.ngoId,
    required this.requestId,
    required this.matchedItems,
    required this.matchScore,
    required this.email,
    required this.phone,
    required this.address,
  });
}

// Data class for donation requests available to NGOs
class DonationRequest {
  final String documentId;
  final String donorId;
  final String requestId;
  final List<dynamic> items;
  final Timestamp addedDate;
  final String email;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? distance;

  DonationRequest({
    required this.documentId,
    required this.donorId,
    required this.requestId,
    required this.items,
    required this.addedDate,
    required this.email,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
    this.distance,
  });
}

// Data class for matched donation requests
class MatchedDonationRequest {
  final DonationRequest donation;
  final Map<String, dynamic> matchedItems;
  final double matchScore;

  MatchedDonationRequest({
    required this.donation,
    required this.matchedItems,
    required this.matchScore,
  });
}

// Data class for accepted/fulfilled donations
class AcceptedDonation {
  final String documentId;
  final String donorId;
  final String requestId;
  final List<dynamic> items;
  final Timestamp acceptedDate;
  final bool isFulfilled;
  final String email;
  final String phone;
  final String address;
  final String? acceptedByNgoId;

  AcceptedDonation({
    required this.documentId,
    required this.donorId,
    required this.requestId,
    required this.items,
    required this.acceptedDate,
    required this.isFulfilled,
    required this.email,
    required this.phone,
    required this.address,
    this.acceptedByNgoId,
  });
}

// Data class for NGO request history
class NGORequestHistory {
  final String documentId;
  final String requestId;
  final List<Map<String, dynamic>> items;
  final Timestamp addedDate;
  final List<String> matchedDonorIds;
  final String? acceptedDonorId;
  final Timestamp? acceptedDate;
  final String donorEmail;
  final String donorPhone;
  final String donorAddress;
  final String status;

  NGORequestHistory({
    required this.documentId,
    required this.requestId,
    required this.items,
    required this.addedDate,
    required this.matchedDonorIds,
    this.acceptedDonorId,
    this.acceptedDate,
    this.donorEmail = '',
    this.donorPhone = '',
    this.donorAddress = '',
    required this.status,
  });
}
