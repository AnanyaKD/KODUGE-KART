import 'package:flutter/material.dart';
import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/utils/data_migration_service.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool isMigrating = false;
  Map<String, dynamic> migrationStatus = {};
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    checkMigrationStatus();
  }

  Future<void> checkMigrationStatus() async {
    try {
      Map<String, dynamic> status = await DataMigrationService.getMigrationStatus();
      setState(() {
        migrationStatus = status;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error checking migration status: $e';
      });
    }
  }

  Future<void> runMigration() async {
    setState(() {
      isMigrating = true;
      statusMessage = 'Starting migration...';
    });

    try {
      await DataMigrationService.runCompleteMigration();
      
      // Refresh status after migration
      await checkMigrationStatus();
      
      setState(() {
        isMigrating = false;
        statusMessage = 'Migration completed successfully!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data migration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isMigrating = false;
        statusMessage = 'Migration failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Migration Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Migration Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (migrationStatus.isNotEmpty) ...[
                      _buildStatusRow('Donor Records', 
                        migrationStatus['donorMigrated'] ?? 0, 
                        migrationStatus['donorTotal'] ?? 0),
                      const SizedBox(height: 8),
                      _buildStatusRow('NGO Records', 
                        migrationStatus['ngoMigrated'] ?? 0, 
                        migrationStatus['ngoTotal'] ?? 0),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (migrationStatus['isComplete'] ?? false) 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (migrationStatus['isComplete'] ?? false) 
                              ? Colors.green 
                              : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (migrationStatus['isComplete'] ?? false) 
                                ? Icons.check_circle 
                                : Icons.warning,
                              color: (migrationStatus['isComplete'] ?? false) 
                                ? Colors.green 
                                : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (migrationStatus['isComplete'] ?? false)
                                  ? 'Migration Complete'
                                  : 'Migration Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (migrationStatus['isComplete'] ?? false) 
                                    ? Colors.green 
                                    : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Migration Actions
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Migration Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (statusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          statusMessage,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isMigrating ? null : runMigration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.textColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isMigrating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Migrating...'),
                                  ],
                                )
                              : const Text('Run Migration'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isMigrating ? null : checkMigrationStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What is Migration?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This migration converts your existing donation data from the old string format to the new structured JSON format. This enables:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Better quantity-based matching\n'
                      '• Unique request IDs for tracking\n'
                      '• Proper acceptance tracking\n'
                      '• Elimination of duplicate donations',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ Migration is safe and can be run multiple times. Existing data will not be lost.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int migrated, int total) {
    double percentage = total > 0 ? (migrated / total) * 100 : 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          '$migrated / $total (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: percentage == 100 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
} 