import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens and features reach the backend only through repositories.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('only core/network and core/errors import Dio', () {
    for (final file in sources) {
      final path = rel(file);
      if (path.contains('lib/core/network/') || path.contains('lib/core/errors/')) {
        continue;
      }
      expect(
        file.readAsStringSync().contains('package:dio/'),
        isFalse,
        reason: path,
      );
    }
  });

  test('no screen builds a URL or names an endpoint path', () {
    for (final file in sources.where((f) => rel(f).contains('/screens/'))) {
      final text = file.readAsStringSync();
      expect(text.contains('http://') || text.contains('https://'), isFalse, reason: rel(file));
      expect(text.contains("'/organizations"), isFalse, reason: rel(file));
      expect(text.contains('Endpoints.'), isFalse, reason: rel(file));
    }
  });

  test('nothing logs', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(RegExp(r'\b(print|debugPrint|log)\(').hasMatch(text), isFalse, reason: rel(file));
    }
  });
}
