part of 'structs.dart';

class Request {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final DateTime createdAt;
  final String status; // 'open', 'closed', 'in_progress'
  final int commentCount;
  final String location;

  Request({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    required this.createdAt,
    required this.status,
    required this.commentCount,
    required this.location,
  });

  factory Request.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Request(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'open',
      commentCount: data['commentCount'] ?? 0,
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
      'commentCount': commentCount,
      'location': location,
    };
  }
}