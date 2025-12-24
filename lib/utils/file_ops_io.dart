import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<void> saveFile(String content, String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Circuit',
      fileName: fileName,
    );

    if (outputFile != null) {
      await File(outputFile).writeAsString(content);
    }
  }

  static Future<void> saveFileToPath(String path, String content) async {
    await File(path).writeAsString(content);
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.path != null) {
      return await File(file.path!).readAsString();
    }
    return "";
  }

  static Future<String?> getAssetsDirectory() async {
    final path = "${Directory.current.path}${Platform.pathSeparator}assets";
    if (await Directory(path).exists()) {
      return path;
    }
    return null; // Fallback to system default if assets doesn't exist
  }
}
