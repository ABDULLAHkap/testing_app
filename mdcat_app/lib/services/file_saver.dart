// Cross-platform PDF saving: triggers a real browser download on Flutter
// Web, and writes to the app's documents folder on Android/iOS/desktop.
// The actual implementation is picked at compile time based on platform.
export 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';
