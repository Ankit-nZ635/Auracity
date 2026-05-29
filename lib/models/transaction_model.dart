import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String title;
  final DateTime timestamp;
  final String toId; // Resolver ID
  final String issueId;
  final String type; // 'ai' or 'manual'

  TransactionModel({
    required this.id,
    required this.amount,
    required this.title,
    required this.timestamp,
    required this.toId,
    required this.issueId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
      'toId': toId,
      'issueId': issueId,
      'type': type,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      toId: data['toId'] ?? '',
      issueId: data['issueId'] ?? '',
      type: data['type'] ?? 'ai',
    );
  }
}
