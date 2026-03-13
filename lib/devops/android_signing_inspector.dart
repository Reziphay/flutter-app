final RegExp _sha256LinePattern = RegExp(
  r'SHA[- ]?256:\s*([0-9A-Fa-f:]{32,})',
  multiLine: true,
);

Set<String> extractSha256Fingerprints(String content) {
  return {
    for (final match in _sha256LinePattern.allMatches(content))
      _normalizeFingerprint(match.group(1)!),
  };
}

String _normalizeFingerprint(String value) {
  return value
      .split(':')
      .map((segment) => segment.trim().toUpperCase())
      .where((segment) => segment.isNotEmpty)
      .join(':');
}
