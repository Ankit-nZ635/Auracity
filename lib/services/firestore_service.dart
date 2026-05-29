import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('reports').child(fileName);
      final snapshot = await ref.putData(await image.readAsBytes()).timeout(const Duration(seconds: 5));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image Upload Error/Timeout: \$e");
      return 'https://via.placeholder.com/400x300.png?text=Image+Unavailable';
    }
  }

  Stream<List<Issue>> getLiveIssues() {
    return _db.collection('issues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Issue.fromFirestore(doc)).toList();
    });
  }

  Future<void> addIssue(Issue issue) async {
    await _db.collection('issues').doc(issue.id).set(issue.toMap()).timeout(const Duration(seconds: 10));
  }

  Future<void> updateIssuePriority(String issueId, String newPriority, String newDepartment) async {
    await _db.collection('issues').doc(issueId).update({
      'priority': newPriority,
      'department': newDepartment,
    });
  }

  Future<void> initializeAdminBudget() async {
    final adminRef = _db.collection('users').doc('admin_sys_001');
    final doc = await adminRef.get();
    if (!doc.exists || (doc.data()?['budget'] ?? 0.0) == 0.0) {
      await adminRef.set({
        'id': 'admin_sys_001',
        'name': 'Administrator',
        'email': 'admin@auracity.gov',
        'role': 'admin',
        'budget': 500000.0,
        'points': 0,
        'resolvedCount': 0,
        'badges': [],
      }, SetOptions(merge: true));
    }
  }

  Future<void> dispatchBatch(List<Issue> issues, String resolverId) async {
    final batch = _db.batch();
    for (var issue in issues) {
      batch.update(_db.collection('issues').doc(issue.id), {
        'status': 'in_progress',
        'resolverId': resolverId,
      });
    }
    await batch.commit();
  }

  Future<void> finalizeResolutionBatch(List<Issue> issues, String imageUrl, String notes, double payoutAmount, int workRating) async {
    if (issues.isEmpty) return;
    
    final batch = _db.batch();
    final adminRef = _db.collection('users').doc('admin_sys_001');
    final String paymentStatus = payoutAmount > 0 ? 'paid' : 'pending';

    // 1. Update all issues in the cluster
    for (var issue in issues) {
      batch.update(_db.collection('issues').doc(issue.id), {
        'status': 'resolved',
        'resolutionImage': imageUrl,
        'resolutionNotes': notes,
        'aiResolutionFeedback': 'Verified by AI System - Batch Resolution',
        'payoutAmount': payoutAmount, 
        'paymentStatus': paymentStatus,
        'workRating': workRating, // AI rating for the work
      });
    }

    // 2. Reward all reporters in the cluster
    for (var issue in issues) {
      if (issue.reporterId != 'anonymous_user') {
        final userRef = _db.collection('users').doc(issue.reporterId);
        batch.update(userRef, {
          'points': FieldValue.increment(1),
          'resolvedCount': FieldValue.increment(1),
        });
      }
    }

    // 3. Update Admin Global Stats
    batch.update(adminRef, {
      'resolvedCount': FieldValue.increment(issues.length),
    });

    // 4. Process Salary & Rating (if AI determined amount)
    final mainIssue = issues.first;
    if (mainIssue.resolverId != null && payoutAmount > 0) {
      final resRef = _db.collection('users').doc(mainIssue.resolverId!);
      
      // Update budgets and ratings
      batch.update(resRef, {
        'walletBalance': FieldValue.increment(payoutAmount),
        'resolvedCount': FieldValue.increment(issues.length),
        'totalRatings': FieldValue.increment(1), // Rated as a cluster
        'totalRatingValue': FieldValue.increment(workRating.toDouble()),
      });
      batch.update(adminRef, {
        'budget': FieldValue.increment(-payoutAmount),
      });

      // Log Transaction
      final transId = _db.collection('financials').doc().id;
      batch.set(_db.collection('financials').doc(transId), {
        'id': transId,
        'amount': payoutAmount,
        'title': 'Salary: ${mainIssue.title}${issues.length > 1 ? ' (+${issues.length - 1} more)' : ''}',
        'timestamp': FieldValue.serverTimestamp(),
        'toId': mainIssue.resolverId,
        'issueId': mainIssue.id,
        'type': 'ai',
        'rating': workRating,
      });
    }

    await batch.commit();
  }

  Future<void> processManualPayment(Issue issue, double amount) async {
    final batch = _db.batch();
    final adminRef = _db.collection('users').doc('admin_sys_001');
    final resRef = _db.collection('users').doc(issue.resolverId!);
    final issueRef = _db.collection('issues').doc(issue.id);

    batch.update(issueRef, {
      'payoutAmount': amount,
      'paymentStatus': 'paid',
    });
    batch.update(resRef, {
      'walletBalance': FieldValue.increment(amount),
    });
    batch.update(adminRef, {
      'budget': FieldValue.increment(-amount),
    });

    final transId = _db.collection('financials').doc().id;
    batch.set(_db.collection('financials').doc(transId), {
      'id': transId,
      'amount': amount,
      'title': 'Manual Payout: ${issue.title}',
      'timestamp': FieldValue.serverTimestamp(),
      'toId': issue.resolverId,
      'issueId': issue.id,
      'type': 'manual',
    });

    await batch.commit();
  }
  
  Future<void> upvoteIssue(String issueId) async {
    await _db.collection('issues').doc(issueId).update({
      'upvotes': FieldValue.increment(1),
    });
  }

  // --- USER PROFILE & LEADERBOARD ---

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Stream<UserModel?> getUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        if (userId == 'admin_sys_001') {
           return UserModel(id: userId, name: 'Administrator', email: 'admin@auracity.gov', points: 0, role: 'admin', badges: [], budget: 500000.0, walletBalance: 0.0);
        }
        if (userId.endsWith('_resolver_001')) {
           return UserModel(id: userId, name: 'Department Resolver', email: '$userId@auracity.gov', points: 0, role: 'resolver', badges: [], walletBalance: 0.0);
        }
        return null;
      }
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _db.collection('financials')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }

  Stream<List<Issue>> getIssuesByUser(String userId) {
    return _db.collection('issues')
      .where('reporterId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Issue.fromFirestore(doc)).toList());
  }

  Stream<List<UserModel>> getTopUsers() {
    return _db.collection('users')
      .where('role', isEqualTo: 'user')
      .orderBy('points', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UserModel>> getTopResolvers() {
    return _db.collection('users')
      .where('role', isEqualTo: 'resolver')
      .orderBy('points', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<void> withdrawIssue(String issueId) async {
    await _db.collection('issues').doc(issueId).delete();
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  Future<bool> isUsernameUnique(String username) async {
    final query = await _db.collection('users')
      .where('username', isEqualTo: username.toLowerCase())
      .limit(1)
      .get();
    return query.docs.isEmpty;
  }

  // --- GLOBAL CITY METADATA ---

  Stream<String> getGlobalMood() {
    return _db.collection('metadata').doc('cityinfo').snapshots().map((doc) {
      if (!doc.exists) {
        // Initialize if doesn't exist
        _db.collection('metadata').doc('cityinfo').set({'globalMood': '😊'});
        return '😊';
      }
      return (doc.data() as Map<String, dynamic>)['globalMood'] ?? '😊';
    });
  }

  Future<void> updateGlobalMood(String emoji) async {
    await _db.collection('metadata').doc('cityinfo').update({
      'globalMood': emoji,
    });
  }

  // --- DEMOCRATIC MOOD VOTING (Majority Rule) ---

  Future<void> updateUserMoodVote(String userId, String emoji) async {
    await _db.collection('mood_votes').doc(userId).set({
      'emoji': emoji,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<String> getMajorityMoodStream() {
    return _db.collection('mood_votes').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return '😊';

      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        
        // Only count votes from the last 2 hours
        if (timestamp != null && timestamp.isAfter(twoHoursAgo)) {
          final emoji = data['emoji'] as String;
          counts[emoji] = (counts[emoji] ?? 0) + 1;
        }
      }

      if (counts.isEmpty) return '😊';

      // Find the emoji with the max votes
      return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    });
  }
}
