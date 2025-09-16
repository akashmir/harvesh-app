class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isFarmer;
  final double? farmSize;
  final String? farmType;
  final List<String> cropPreferences;
  final Map<String, dynamic>? location;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.createdAt,
    this.lastLoginAt,
    this.isFarmer = true,
    this.farmSize,
    this.farmType,
    this.cropPreferences = const [],
    this.location,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      photoURL: map['photoURL'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toDate().toIso8601String())
          : null,
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'].toDate().toIso8601String())
          : null,
      isFarmer: map['isFarmer'] ?? true,
      farmSize: map['farmSize']?.toDouble(),
      farmType: map['farmType'],
      cropPreferences: List<String>.from(map['cropPreferences'] ?? []),
      location: map['location'] != null
          ? Map<String, dynamic>.from(map['location'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'isFarmer': isFarmer,
      'farmSize': farmSize,
      'farmType': farmType,
      'cropPreferences': cropPreferences,
      'location': location,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isFarmer,
    double? farmSize,
    String? farmType,
    List<String>? cropPreferences,
    Map<String, dynamic>? location,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isFarmer: isFarmer ?? this.isFarmer,
      farmSize: farmSize ?? this.farmSize,
      farmType: farmType ?? this.farmType,
      cropPreferences: cropPreferences ?? this.cropPreferences,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, phoneNumber: $phoneNumber, photoURL: $photoURL, createdAt: $createdAt, lastLoginAt: $lastLoginAt, isFarmer: $isFarmer, farmSize: $farmSize, farmType: $farmType, cropPreferences: $cropPreferences, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.phoneNumber == phoneNumber &&
        other.photoURL == photoURL &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.isFarmer == isFarmer &&
        other.farmSize == farmSize &&
        other.farmType == farmType &&
        other.cropPreferences == cropPreferences &&
        other.location == location;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        phoneNumber.hashCode ^
        photoURL.hashCode ^
        createdAt.hashCode ^
        lastLoginAt.hashCode ^
        isFarmer.hashCode ^
        farmSize.hashCode ^
        farmType.hashCode ^
        cropPreferences.hashCode ^
        location.hashCode;
  }
}
