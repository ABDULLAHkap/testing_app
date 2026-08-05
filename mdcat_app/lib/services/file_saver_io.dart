import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to the app's documents folder as [filename], then opens
/// the native Share sheet so the user can save it to Downloads, send it
/// via WhatsApp, etc. Returns the file path written.
Future<String> savePdf(List<int> bytes, String filename) async {
  final dir = await path_provider.getApplicationDocumentsDirectory();
  final file = File("${dir.path}/$filename");
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    text: 'Your MDCAT quiz result',
  );

  return file.path;
}
