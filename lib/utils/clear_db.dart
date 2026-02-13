import 'dart:io';
import '../../core/services/database_service.dart';

Future<void> main() async {
  print('Clearing all database data...');

  try {
    final dbService = DatabaseService();
    await dbService.clearAllDataIncludingUsers();
    print('✅ Database cleared successfully!');
    await dbService.close();
  } catch (e) {
    print('❌ Error clearing database: $e');
    exit(1);
  }
}
