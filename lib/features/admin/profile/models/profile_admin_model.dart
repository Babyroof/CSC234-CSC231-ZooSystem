class ProfileAdminModel {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String username;
  final String phoneNumber;

  const ProfileAdminModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.username,
    required this.phoneNumber,
  });

  factory ProfileAdminModel.fromMap(String id, Map<String, dynamic> map) {
    return ProfileAdminModel(
      id: id,
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
