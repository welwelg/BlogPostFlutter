class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      // 👇 DITO TAYO MAG-ADJUST:
      // Map 'display_name' (DB) to 'fullName' (Flutter)
      fullName: json['display_name'],

      // Map 'profile_image' (DB) to 'avatarUrl' (Flutter)
      avatarUrl: json['profile_image'],

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
