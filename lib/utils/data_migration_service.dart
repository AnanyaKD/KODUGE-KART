import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koduge_kart/models/donor_model.dart';
import 'package:koduge_kart/models/ngo_model.dart';
import 'package:koduge_kart/utils/matching_service.dart';

class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate donor data from old format to new format
  static Future<void> migrateDonorData() async {
    try {
      print('Starting donor data migration...');

      QuerySnapshot donorSnapshot =
          await _firestore.collection('donorfood').get();
      int migratedCount = 0;
      int skippedCount = 0;

      for (var doc in donorSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if already migrated (has new structure)
        if (data.containsKey('items') && data.containsKey('requestId')) {
          print('Document ${doc.id} already migrated, skipping...');
          skippedCount++;
          continue;
        }

        // Parse old format: "Item (Quantity), Item2 (Quantity2)"
        String oldFoodName = data['foodName'] ?? '';
        List<Map<String, dynamic>> items = _parseOldFormat(oldFoodName);

        if (items.isNotEmpty) {
          // Create new donor model
          DonorModel newDonorModel = DonorModel(
            donorId: data['donorId'] ?? '',
            requestId: data['requestId'] ?? MatchingService.generateRequestId(),
            items: items,
            addeddate: data['addeddate'] ?? Timestamp.now(),
            isfulfilled: data['isfulfilled'] ?? false,
            matchedNgoIds: List<String>.from(data['matchedNgoIds'] ?? []),
            acceptedByNgoId: data['acceptedByNgoId'],
            acceptedDate: data['acceptedDate'],
          );

          // Update the document with new structure
          await _firestore
              .collection('donorfood')
              .doc(doc.id)
              .update(newDonorModel.toMap());
          migratedCount++;
          print('Migrated donor document ${doc.id}');
        }
      }

      print(
        'Donor migration completed: $migratedCount migrated, $skippedCount skipped',
      );
    } catch (e) {
      print('Error migrating donor data: $e');
      throw e;
    }
  }

  // Migrate NGO data from old format to new format
  static Future<void> migrateNGOData() async {
    try {
      print('Starting NGO data migration...');

      QuerySnapshot ngoSnapshot = await _firestore.collection('ngofood').get();
      int migratedCount = 0;
      int skippedCount = 0;

      for (var doc in ngoSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if already migrated (has new structure)
        if (data.containsKey('items') && data.containsKey('requestId')) {
          print('Document ${doc.id} already migrated, skipping...');
          skippedCount++;
          continue;
        }

        // Parse old format: "Item (Quantity), Item2 (Quantity2)"
        String oldFoodName = data['foodName'] ?? '';
        List<Map<String, dynamic>> items = _parseOldFormat(oldFoodName);

        if (items.isNotEmpty) {
          // Create new NGO model
          NGOModel newNGOModel = NGOModel(
            ngoId: data['ngoId'] ?? '',
            requestId: data['requestId'] ?? MatchingService.generateRequestId(),
            items: items,
            addeddate: data['addeddate'] ?? Timestamp.now(),
            matchedDonorIds: List<String>.from(data['matchedDonorIds'] ?? []),
            acceptedDonorId: data['acceptedDonorId'],
            acceptedDate: data['acceptedDate'],
          );

          // Update the document with new structure
          await _firestore
              .collection('ngofood')
              .doc(doc.id)
              .update(newNGOModel.toMap());
          migratedCount++;
          print('Migrated NGO document ${doc.id}');
        }
      }

      print(
        'NGO migration completed: $migratedCount migrated, $skippedCount skipped',
      );
    } catch (e) {
      print('Error migrating NGO data: $e');
      throw e;
    }
  }

  // Parse old format string into structured items
  static List<Map<String, dynamic>> _parseOldFormat(String oldFormat) {
    List<Map<String, dynamic>> items = [];

    if (oldFormat.isEmpty) return items;

    // Split by comma and process each item
    List<String> itemStrings =
        oldFormat.split(',').map((s) => s.trim()).toList();

    for (String itemString in itemStrings) {
      // Parse format: "Item Name (Quantity Unit)"
      RegExp regex = RegExp(r'^(.+?)\s*\((\d+)\s*(.+?)\)$');
      Match? match = regex.firstMatch(itemString);

      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        int quantity = int.tryParse(match.group(2) ?? '0') ?? 0;
        String unit = match.group(3)?.trim() ?? 'units';

        if (name.isNotEmpty && quantity > 0) {
          items.add({'name': name, 'quantity': quantity, 'unit': unit});
        }
      }
    }

    return items;
  }

  // Run complete migration including match updates
  static Future<void> runCompleteMigration() async {
    try {
      print('Starting complete data migration...');

      await migrateDonorData();
      await migrateNGOData();

      // // Update existing donations with matches
      // await MatchingService.updateExistingDonationsWithMatches();

      print('Complete data migration finished successfully!');
    } catch (e) {
      print('Error during complete migration: $e');
      throw e;
    }
  }

  // Check migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      QuerySnapshot donorSnapshot =
          await _firestore.collection('donorfood').get();
      QuerySnapshot ngoSnapshot = await _firestore.collection('ngofood').get();

      int donorTotal = donorSnapshot.docs.length;
      int ngoTotal = ngoSnapshot.docs.length;

      int donorMigrated = 0;
      int ngoMigrated = 0;

      for (var doc in donorSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('items') && data.containsKey('requestId')) {
          donorMigrated++;
        }
      }

      for (var doc in ngoSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('items') && data.containsKey('requestId')) {
          ngoMigrated++;
        }
      }

      return {
        'donorTotal': donorTotal,
        'donorMigrated': donorMigrated,
        'donorPending': donorTotal - donorMigrated,
        'ngoTotal': ngoTotal,
        'ngoMigrated': ngoMigrated,
        'ngoPending': ngoTotal - ngoMigrated,
        'isComplete':
            (donorTotal == donorMigrated) && (ngoTotal == ngoMigrated),
      };
    } catch (e) {
      print('Error getting migration status: $e');
      return {'error': e.toString(), 'isComplete': false};
    }
  }
}
