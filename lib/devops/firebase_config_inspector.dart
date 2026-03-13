import 'dart:convert';

String? extractIosFirebaseBundleId(String content) {
  final pattern = RegExp(
    '<key>${RegExp.escape('BUNDLE_ID')}</key>\\s*<string>([^<]+)</string>',
    multiLine: true,
  );
  return pattern.firstMatch(content)?.group(1);
}

Set<String> extractAndroidFirebasePackageNames(String content) {
  final parsed = jsonDecode(content);
  if (parsed is! Map<String, dynamic>) {
    return <String>{};
  }

  return <String>{
    for (final client
        in parsed['client'] as List<dynamic>? ?? const <dynamic>[])
      if (client is Map<String, dynamic>) _extractAndroidPackageName(client),
  }..removeWhere((value) => value.isEmpty);
}

String _extractAndroidPackageName(Map<String, dynamic> client) {
  final clientInfo = client['client_info'];
  if (clientInfo is! Map<String, dynamic>) {
    return '';
  }
  final androidInfo = clientInfo['android_client_info'];
  if (androidInfo is! Map<String, dynamic>) {
    return '';
  }
  return androidInfo['package_name'] as String? ?? '';
}
