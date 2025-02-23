part of 'structs.dart';

class User {
  final String uid;
  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime birthdate;
  final String gender;
  final DateTime createdAt;
  final String profileImage;

  User({
    required this.uid,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.birthdate,
    required this.gender,
    required this.createdAt,
    required this.profileImage,
  });

  // Factory method to create a User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      birthdate: (data['birthdate'] as Timestamp).toDate(),
      gender: data['gender'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      profileImage: data['profileImage'] ?? ''
    );
  }

  // Method to convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthdate': Timestamp.fromDate(birthdate),
      'gender': gender,
      'createdAt': FieldValue.serverTimestamp(),
      'profileImage': profileImage
    };
  }
}