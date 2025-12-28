import 'dart:html' as html;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<PlatformFile?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    return result?.files.single;
  }

  static Future<String?> saveFile(String content, String fileName) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  static Future<String?> saveFileToPath(String path, String content) async {
    // If saving blueprints, use LocalStorage
    if (path.contains("blueprints.json")) {
      html.window.localStorage['blueprints'] = content;
      print("Saved blueprints to LocalStorage");
      return ""; // Return null as saveFile returns String?
    }

    // Otherwise fallback to download
    String fileName = path.split('/').last.split('\\').last;
    return await saveFile(content, fileName);
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    return "";
  }

  static Future<String> readFileFromPath(String path) async {
    if (path.contains("blueprints.json")) {
      final content = html.window.localStorage['blueprints'];
      if (content != null) {
        print("Read blueprints from LocalStorage");
        return content;
      }
    }
    return "";
  }

  static Future<String?> getAssetsDirectory() async {
    // Return a dummy path to pass null check in CircuitProvider
    return "WEB_STORAGE";
  }

  static String get pathSeparator => '/';
}
