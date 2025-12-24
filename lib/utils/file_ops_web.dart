import 'dart:html' as html;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<void> saveFile(String content, String fileName) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> saveFileToPath(String path, String content) async {
    // Web cannot overwrite arbitrary paths. Fallback to download or ignore?
    // Best behavior: Trigger download with same name
    // Extract filename from path?
    String fileName = path.split('/').last.split('\\').last; // Simple logic
    await saveFile(content, fileName);
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    return "";
  }

  static Future<String?> getAssetsDirectory() async {
    return null;
  }
}
