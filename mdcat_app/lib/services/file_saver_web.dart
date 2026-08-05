import 'dart:html' as html;

/// Triggers a browser download of [bytes] as [filename]. Returns [filename]
/// since there's no real filesystem path on web — the browser handles where
/// it lands (usually the user's Downloads folder).
Future<String> savePdf(List<int> bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}
