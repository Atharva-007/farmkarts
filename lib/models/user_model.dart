enum UserRole { farmer, addat }

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String fullName;
  final String mobileNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    required this.mobileNo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.toString().split('.').last,
      'fullName': fullName,
      'mobileNo': mobileNo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.farmer,
      ),
      fullName: map['fullName'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}

class FarmerModel extends UserModel {
  final double acresLand;

  FarmerModel({
    required String uid,
    required String email,
    required String fullName,
    required String mobileNo,
    required this.acresLand,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          uid: uid,
          email: email,
          role: UserRole.farmer,
          fullName: fullName,
          mobileNo: mobileNo,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['acresLand'] = acresLand;
    return map;
  }

  factory FarmerModel.fromMap(Map<String, dynamic> map) {
    return FarmerModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      acresLand: (map['acresLand'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  FarmerModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? mobileNo,
    double? acresLand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      mobileNo: mobileNo ?? this.mobileNo,
      acresLand: acresLand ?? this.acresLand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class AddatModel extends UserModel {
  final String dukanName;
  final String? licenseImageUrl; // Made optional
  final bool isLicenseVerified;
  final DateTime? licenseUploadedAt; // Track when license was uploaded
  final String? verificationNotes; // Admin can add notes

  AddatModel({
    required String uid,
    required String email,
    required String fullName,
    required String mobileNo,
    required this.dukanName,
    this.licenseImageUrl, // Optional now
    this.isLicenseVerified = false,
    this.licenseUploadedAt,
    this.verificationNotes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          uid: uid,
          email: email,
          role: UserRole.addat,
          fullName: fullName,
          mobileNo: mobileNo,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['dukanName'] = dukanName;
    map['licenseImageUrl'] = licenseImageUrl; // Will be null if not uploaded
    map['isLicenseVerified'] = isLicenseVerified;
    map['licenseUploadedAt'] = licenseUploadedAt?.millisecondsSinceEpoch;
    map['verificationNotes'] = verificationNotes;
    return map;
  }

  factory AddatModel.fromMap(Map<String, dynamic> map) {
    return AddatModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      dukanName: map['dukanName'] ?? '',
      licenseImageUrl: map['licenseImageUrl'], // Can be null
      isLicenseVerified: map['isLicenseVerified'] ?? false,
      licenseUploadedAt: map['licenseUploadedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['licenseUploadedAt'])
          : null,
      verificationNotes: map['verificationNotes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  AddatModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? mobileNo,
    String? dukanName,
    String? licenseImageUrl,
    bool? isLicenseVerified,
    DateTime? licenseUploadedAt,
    String? verificationNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddatModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      mobileNo: mobileNo ?? this.mobileNo,
      dukanName: dukanName ?? this.dukanName,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      isLicenseVerified: isLicenseVerified ?? this.isLicenseVerified,
      licenseUploadedAt: licenseUploadedAt ?? this.licenseUploadedAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}