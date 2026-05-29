import 'package:cloud_firestore/cloud_firestore.dart';

class Issue {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String priority; // Urgent, General, Normal
  final String status; // open, in_progress, resolved
  final int upvotes;
  final String reporterId;
  final DateTime createdAt;
  final String department;
  final String? fakeProbability;
  final String emoji;
  final String? detailedType; // e.g. "Road Broken -> Pothole"
  final String? estimatedTime; // e.g. "48 Hours"
  final String? resolverId;
  final String? resolutionImage;
  final String? resolutionNotes;

  final int? points; // points awarded
  final String? aiSummary; // AI generated summary of the issue
  final String? aiResolutionFeedback; // AI feedback on resolving the issue
  final double? payoutAmount; // amount paid in INR
  final String? paymentStatus; // 'paid', 'pending'
  final int? workRating; // 1-5 rating from AI

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.priority,
    required this.status,
    required this.upvotes,
    required this.reporterId,
    required this.createdAt,
    required this.department,
    this.fakeProbability,
    required this.emoji,
    this.detailedType,
    this.estimatedTime,
    this.resolverId,
    this.resolutionImage,
    this.resolutionNotes,
    this.points,
    this.aiSummary,
    this.aiResolutionFeedback,
    this.payoutAmount,
    this.paymentStatus,
    this.workRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'priority': priority,
      'status': status,
      'upvotes': upvotes,
      'reporterId': reporterId,
      'createdAt': Timestamp.fromDate(createdAt),
      'department': department,
      'fakeProbability': fakeProbability,
      'emoji': emoji,
      'detailedType': detailedType,
      'estimatedTime': estimatedTime,
      'resolverId': resolverId,
      'resolutionImage': resolutionImage,
      'resolutionNotes': resolutionNotes,
      'points': points,
      'aiSummary': aiSummary,
      'aiResolutionFeedback': aiResolutionFeedback,
      'payoutAmount': payoutAmount,
      'paymentStatus': paymentStatus,
      'workRating': workRating,
    };
  }

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Issue(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      priority: data['priority'] ?? 'General',
      status: data['status'] ?? 'open',
      upvotes: data['upvotes'] ?? 0,
      reporterId: data['reporterId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      department: data['department'] ?? 'General',
      fakeProbability: data['fakeProbability'],
      emoji: data['emoji'] ?? '📍',
      detailedType: data['detailedType'],
      estimatedTime: data['estimatedTime'],
      resolverId: data['resolverId'],
      resolutionImage: data['resolutionImage'],
      resolutionNotes: data['resolutionNotes'],
      points: data['points'] ?? 0,
      aiSummary: data['aiSummary'],
      aiResolutionFeedback: data['aiResolutionFeedback'],
      payoutAmount: (data['payoutAmount'] ?? 0.0).toDouble(),
      paymentStatus: data['paymentStatus'],
      workRating: data['workRating'],
    );
  }
}
