class UserModel {
  final String id;
  final String name;
  final String email;
  final int points;
  final String role; // 'user', 'admin', 'resolver'
  final List<String> badges;
  final int resolvedCount;
  final String? department;
  
  // Expanded Profile Fields
  final String? username;
  final String? photoUrl;
  final String? bio;
  final String? phoneNumber;
  final String? occupation;
  final String? location;
  final double walletBalance;
  final double budget;
  final double averageRating;
  final int totalRatings;
  final double totalRatingValue; // Sum of all stars

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.role,
    required this.badges,
    this.resolvedCount = 0,
    this.department,
    this.username,
    this.photoUrl,
    this.bio,
    this.phoneNumber,
    this.occupation,
    this.location,
    this.walletBalance = 0.0,
    this.budget = 0.0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalRatingValue = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'points': points,
      'role': role,
      'badges': badges,
      'resolvedCount': resolvedCount,
      'department': department,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'occupation': occupation,
      'location': location,
      'walletBalance': walletBalance,
      'budget': budget,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalRatingValue': totalRatingValue,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      points: map['points'] ?? 0,
      role: map['role'] ?? 'user',
      badges: List<String>.from(map['badges'] ?? []),
      resolvedCount: map['resolvedCount'] ?? 0,
      department: map['department'],
      username: map['username'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      occupation: map['occupation'],
      location: map['location'],
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      budget: (map['budget'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalRatingValue: (map['totalRatingValue'] ?? 0.0).toDouble(),
    );
  }
}
