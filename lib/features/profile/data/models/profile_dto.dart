import '../../../auth/domain/entities/user_entity.dart';

class ProfileDto {
  const ProfileDto({
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

  factory ProfileDto.fromJson(Map<String, dynamic> json, String uid) {
    return ProfileDto(
      uid: uid,
      email: json['email'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      username: json['username'] ?? '',
    );
  }

  UserEntity toEntity() => UserEntity(
    uid: uid,
    email: email,
    firstname: firstname,
    lastname: lastname,
    phoneNumber: phoneNumber,
    username: username,
  );
}
