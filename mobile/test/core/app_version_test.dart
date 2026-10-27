import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/config/app_config.dart';

void main() {
  test('AppConfig.appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    expect(AppConfig.appVersion, line.substring('version:'.length).trim());
  });
}
