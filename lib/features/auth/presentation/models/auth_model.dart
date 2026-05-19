class UserModel {
  final String uid;
  final String email;
  final String firstname;
  final String lastname;
  final String phoneNumber;
  final String username;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.phoneNumber,
    required this.username,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'phoneNumber': phoneNumber,
      'username': username,
    };
  }
}
