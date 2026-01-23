void main() {
  List<String> files = [
    'path/to/blueprints.json',
    'path/to/blueprint1.json',
    'path/to/blueprint2.json',
    'path/to/blueprint10.json',
    'path/to/blueprint3.json',
    'path/to/other.json',
    'path/to/blueprint9.json',
  ];
  final RegExp versionPattern = RegExp(r'blueprints (\d+)\.json$');

  String? bestFile;
  int maxVersion = -1;

  print('Scanning files:');
  for (String filePath in files) {
    String fileName = filePath.split('/').last;
    final match = versionPattern.firstMatch(fileName);
    if (match != null) {
      int version = int.parse(match.group(1)!);
      print('  Found version $version in $fileName');
      if (version > maxVersion) {
        maxVersion = version;
        bestFile = filePath;
      }
    } else {
      print('  Skipped: $fileName');
    }
  }

  print('Result: Best file: $bestFile (Version $maxVersion)');

  if (maxVersion == 10 && bestFile == 'path/to/blueprint10.json') {
    print('SUCCESS: Correctly identified highest version.');
  } else {
    print('FAILURE: Incorrect file selected.');
    throw Exception('Verification failed');
  }
}
