import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<PlatformFile?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    return result?.files.single;
  }

  static Future<String?> saveFile(String content, String fileName) async {
    // Directly use the fallback/download method
    return _doDownload(content, fileName);
  }

  static Future<String?> _doDownload(String content, String fileName) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  static Future<void> saveFileToPath(String path, String content) async {
    // For web "save to path", we just download the file with the filename part of the path.
    // We cannot write to a specific directory on the user's machine.
    final fileName = path.split(pathSeparator).last;
    await _doDownload(content, fileName);
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    return "";
  }

  static Future<String> readFileFromPath(String path) async {
    // Cannot read from arbitrary path on web without user interaction (picker).
    // If this is for initial load (blueprints.json), we might return empty
    // or rely on previous LocalStorage if that was a requirement, but
    // the instruction says "move back entire persistence layer... to download folder".
    // This implies we don't have automatic persistence reading from that folder.
    return "";
  }

  static Future<String?> getAssetsDirectory() async {
    // No assets directory access on web in this mode.
    return null;
  }

  static String get pathSeparator => '/';
}
