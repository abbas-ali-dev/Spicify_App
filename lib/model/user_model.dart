class UserModel {
  final String uid;
  final String email;
  final String name;
  final String profileImage;
  final String username;
  final String phone;
  final String dob;
  final bool isSubscriber;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.profileImage,
    required this.username,
    required this.phone,
    required this.dob,
    required this.isSubscriber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profileImage': profileImage,
      'username': username,
      'phone': phone,
      'dob': dob,
      'isSubscriber': isSubscriber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profileImage: map['profileImage'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      dob: map['dob'] ?? '',
      isSubscriber: map['isSubscriber'] ?? false,
    );
  }
}
