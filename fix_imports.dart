import 'dart:io';

void main() {
  final directories = ['lib', 'test'];
  for (final dirName in directories) {
    final dir = Directory(dirName);
    if (!dir.existsSync()) continue;
    
    final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    
    for (final file in files) {
      final content = file.readAsStringSync();
      if (content.contains('package:pbrowser/')) {
        final newContent = content.replaceAll('package:pbrowser/', 'package:SecTunnel/');
        file.writeAsStringSync(newContent);
        print('Fixed imports in ${file.path}');
      }
    }
  }
}
