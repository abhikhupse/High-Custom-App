class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String employerCode;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final bool isLogIn;
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
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName:
          json['firstName']?.toString() ?? '',
      lastName:
          json['lastName']?.toString() ?? '',
      employerCode:
          json['employerCode']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      phone:
          json['phone']?.toString() ?? '',
      isEmailVerified:
          json['isEmailVerified'] ?? false,
      isLogIn:
          json['isLogIn'] ?? false,
      createdAt:
          json['createdAt']?.toString(),
      updatedAt:
          json['updatedAt']?.toString(),
    );
  }
}