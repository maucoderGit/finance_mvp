import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;

/// Override the sqlite3 library loading for desktop CI environments.
/// On Linux the app bundles sqlite3 via `sqlite3_flutter_libs`, which is not
/// available to `flutter test`. Point at the system library instead.
/// On macOS use the Homebrew / system path.
/// On iOS/Android `sqlite3_flutter_libs` provides the library automatically.
///
/// [closeStreamsSynchronously] is for widget tests only. Drift otherwise holds a
/// query stream's cache open for one event-loop iteration after the last
/// listener detaches, via `Timer.run` — which trips flutter_test's "a Timer is
/// still pending" invariant when a `StreamBuilder` unmounts. Closing inline
/// costs a duplicate statement on rebuild, irrelevant in a test.
DatabaseConnection testConnection(QueryExecutor executor) =>
    DatabaseConnection(executor, closeStreamsSynchronously: true);

void useSystemSqlite() {
  if (Platform.isLinux) {
    sqlite3_open.open.overrideFor(sqlite3_open.OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'));
  } else if (Platform.isMacOS) {
    sqlite3_open.open.overrideFor(sqlite3_open.OperatingSystem.macOS,
        () => DynamicLibrary.open('libsqlite3.0.dylib'));
  }
}