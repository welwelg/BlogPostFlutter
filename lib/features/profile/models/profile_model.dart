class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  Profile({required this.id, this.username, this.fullName, this.avatarUrl});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }
}
