// category.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final List<CategoryItem> children;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final childList = (json['children'] as List<dynamic>?)
            ?.map((c) => CategoryItem.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return CategoryItem(
      id:       json['id']   as String,
      name:     json['name'] as String,
      slug:     json['slug'] as String,
      children: childList,
    );
  }
}
