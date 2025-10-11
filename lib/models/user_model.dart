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
}

class AddatModel extends UserModel {
  final String dukanName;
  final String licenseImageUrl;
  final bool isLicenseVerified;

  AddatModel({
    required String uid,
    required String email,
    required String fullName,
    required String mobileNo,
    required this.dukanName,
    required this.licenseImageUrl,
    this.isLicenseVerified = false,
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
    map['licenseImageUrl'] = licenseImageUrl;
    map['isLicenseVerified'] = isLicenseVerified;
    return map;
  }

  factory AddatModel.fromMap(Map<String, dynamic> map) {
    return AddatModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      dukanName: map['dukanName'] ?? '',
      licenseImageUrl: map['licenseImageUrl'] ?? '',
      isLicenseVerified: map['isLicenseVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}