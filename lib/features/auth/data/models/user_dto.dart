import '../../domain/entities/user_entity.dart';

class UserDto {
  const UserDto({
    required this.uid,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.phoneNumber,
    required this.username,
  });

  final String uid;
  final String email;
  final String firstname;
  final String lastname;
  final String phoneNumber;
  final String username;

  factory UserDto.fromJson(Map<String, dynamic> json, String uid) {
    return UserDto(
      uid: uid,
      email: json['email'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'firstname': firstname,
    'lastname': lastname,
    'phoneNumber': phoneNumber,
    'username': username,
  };

  UserEntity toEntity() => UserEntity(
    uid: uid,
    email: email,
    firstname: firstname,
    lastname: lastname,
    phoneNumber: phoneNumber,
    username: username,
  );
}
