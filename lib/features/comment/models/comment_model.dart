class Comment {
  final String id;
  final String blogId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? commenterName; // Name of the user who commented
  final String? imageUrl; // 🖼️ URL of the comment image (if any)

  Comment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.commenterName,
    this.imageUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      blogId: map['blog_id'] ?? '',
      userId: map['user_id'] ?? '',
      content: map['comment_text'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      // 🔹 TRICKY PART: Kinukuha natin ang name mula sa 'profiles' table join
      commenterName: (map['profiles'] != null)
          ? map['profiles']['display_name']
          : 'Unknown',
      imageUrl: map['image_url'], // 🖼️ Get image URL if exists
    );
  }
}
