import 'package:file_picker/file_picker.dart';

import 'file_ops_io.dart' if (dart.library.html) 'file_ops_web.dart';

abstract class FileOps {
  static Future<void> saveFile(String content, String fileName) =>
      FileOpsImpl.saveFile(content, fileName);
  static Future<void> saveFileToPath(String path, String content) =>
      FileOpsImpl.saveFileToPath(path, content);
  static Future<String> readFile(PlatformFile file) =>
      FileOpsImpl.readFile(file);
  static Future<String?> getAssetsDirectory() =>
      FileOpsImpl.getAssetsDirectory();
}
