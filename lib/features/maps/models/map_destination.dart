class MapDestination {
  const MapDestination({
    required this.title,
    required this.addressLine,
    this.subtitle,
    this.note,
  });

  final String title;
  final String addressLine;
  final String? subtitle;
  final String? note;

  String get searchQuery => [
    title,
    if (subtitle != null && subtitle!.trim().isNotEmpty) subtitle!.trim(),
    addressLine,
  ].join(', ');
}
