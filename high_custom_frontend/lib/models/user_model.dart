class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String employerCode;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final bool isLogIn;
  final Map<String, bool> appRights;
  final Map<String, bool> accessRights;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.employerCode,
    required this.email,
    required this.phone,
    required this.isEmailVerified,
    required this.isLogIn,
    this.appRights = const {},
    this.accessRights = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      employerCode: json['employerCode']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isLogIn: json['isLogIn'] ?? false,
      appRights: _rights(json['appRights']),
      accessRights: _rights(json['accessRights']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static Map<String, bool> _rights(dynamic source) {
    if (source is! Map) return const {};
    return source.map((key, value) => MapEntry(key.toString(), value == true));
  }

  bool canOpen(String appRight, String accessRight) =>
      appRights[appRight] == true && accessRights[accessRight] == true;
}
