import 'dart:io';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/devops/firebase_config_inspector.dart';

Future<void> main(List<String> args) async {
  final iosSource = _readArg(args, '--ios-plist');
  final androidSource = _readArg(args, '--android-json');

  if (iosSource == null && androidSource == null) {
    stderr.writeln(
      'Pass --ios-plist=/path/to/GoogleService-Info.plist and/or '
      '--android-json=/path/to/google-services.json',
    );
    exitCode = 64;
    return;
  }

  if (iosSource != null) {
    await _installIosConfig(iosSource);
  }

  if (androidSource != null) {
    await _installAndroidConfig(androidSource);
  }

  stdout.writeln('Run `dart run tool/release_preflight.dart` next.');
}

Future<void> _installIosConfig(String sourcePath) async {
  final source = File(sourcePath);
  if (!await source.exists()) {
    stderr.writeln('Missing iOS source file: $sourcePath');
    exitCode = 1;
    return;
  }

  final content = await source.readAsString();
  final bundleId = extractIosFirebaseBundleId(content);
  if (bundleId != iOSBundleId) {
    stderr.writeln(
      'Refusing to install iOS Firebase config. Expected bundle ID '
      '$iOSBundleId but found ${bundleId ?? 'none'}.',
    );
    exitCode = 1;
    return;
  }

  final target = File('ios/Runner/GoogleService-Info.plist');
  await target.writeAsString(content);
  stdout.writeln('Installed ${target.path}');
}

Future<void> _installAndroidConfig(String sourcePath) async {
  final source = File(sourcePath);
  if (!await source.exists()) {
    stderr.writeln('Missing Android source file: $sourcePath');
    exitCode = 1;
    return;
  }

  final content = await source.readAsString();
  final packageNames = extractAndroidFirebasePackageNames(content);
  if (!packageNames.contains(androidApplicationId)) {
    final found = packageNames.isEmpty ? 'none' : packageNames.join(', ');
    stderr.writeln(
      'Refusing to install Android Firebase config. Expected package '
      '$androidApplicationId but found $found.',
    );
    exitCode = 1;
    return;
  }

  final target = File('android/app/google-services.json');
  await target.writeAsString(content);
  stdout.writeln('Installed ${target.path}');
}

String? _readArg(List<String> args, String name) {
  for (final argument in args) {
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
  }
  return null;
}
