import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart' as sqlite3_open;

/// Override the sqlite3 library loading for desktop CI environments.
/// On Linux the app bundles sqlite3 via `sqlite3_flutter_libs`, which is not
/// available to `flutter test`. Point at the system library instead.
/// On macOS use the Homebrew / system path.
/// On iOS/Android `sqlite3_flutter_libs` provides the library automatically.
void useSystemSqlite() {
  if (Platform.isLinux) {
    sqlite3_open.open.overrideFor(sqlite3_open.OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'));
  } else if (Platform.isMacOS) {
    sqlite3_open.open.overrideFor(sqlite3_open.OperatingSystem.macOS,
        () => DynamicLibrary.open('libsqlite3.0.dylib'));
  }
}