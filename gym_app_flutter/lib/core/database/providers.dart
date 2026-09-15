import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

// Database provider - kept alive for entire app lifecycle to prevent multiple instances
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());

  // Keep this provider alive to ensure only one database instance exists
  ref.keepAlive();

  return database;
});
