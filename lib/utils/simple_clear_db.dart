import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('Clearing database...');
  
  try {
    final dbPath = join(await getDatabasesPath(), 'smart_home.db');
    final db = await openDatabase(dbPath);
    
    // Get all table names
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    
    for (final table in tables) {
      final tableName = table['name'] as String;
      if (tableName != 'sqlite_sequence') {
        await db.delete(tableName);
        print('✅ Cleared table: $tableName');
      }
    }
    
    await db.close();
    print('✅ Database cleared successfully!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
