class UserEntity {
  const UserEntity({
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
}
