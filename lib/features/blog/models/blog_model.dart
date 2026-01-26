class Blog {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? imageUrl; // Nullable kasi pwedeng walang image
  final DateTime createdAt;

  Blog({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  // 🔹 factory logic: "Gawin mong Blog Object ang JSON na galing kay Supabase"
  factory Blog.fromJson(Map<String, dynamic> map) {
    return Blog(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '', // Make sure match ito sa column name sa SQL
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // 🔹 "Gawin mong JSON ang Blog Object para ma-upload sa Database"
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}