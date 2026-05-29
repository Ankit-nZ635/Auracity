import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  String? _currentUserRole; // 'admin', 'user', or null
  String? _currentUserId;

  bool get isAuthenticated => _currentUserRole != null;
  bool get isAdmin => _currentUserRole == 'admin';
  bool get isResolver => _currentUserRole == 'resolver';
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) {
      // If we are currently "admin" or "resolver", we don't automatically override it to null 
      // just because Firebase stream says so, since they are static bypasses.
      if (_currentUserRole == 'admin' || _currentUserRole == 'resolver') return;

      if (user != null) {
        _currentUserRole = 'user';
        _currentUserId = user.uid;
      } else {
        _currentUserRole = null;
        _currentUserId = null;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String identifier, String password) async {
    if (identifier == 'admin' && password == 'admin123') {
      _currentUserRole = 'admin';
      _currentUserId = 'admin_sys_001';
      notifyListeners();
      return;
    }

    // Intercept hardcoded resolvers
    if (password == 'resolver123') {
      if (identifier.endsWith('_resolver')) {
        _currentUserRole = 'resolver';
        _currentUserId = '${identifier}_001'; // e.g., water_resolver_001
        notifyListeners();
        return;
      }
    }

    // Normal user login via Firebase Auth
    // Because identifier could just be an arbitrary string but Firebase needs email:
    // If they typed a username, ideally we'd look up their email. For MVP we assume email.
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: identifier.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name, String username) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final db = FirestoreService();
      if (cred.user != null) {
        await cred.user!.updateDisplayName(name);
        
        final newUser = UserModel(
          id: cred.user!.uid,
          name: name,
          username: username.toLowerCase().trim(),
          email: email.trim(),
          points: 0,
          role: 'user',
          badges: ['New Citizen'],
        );
        await db.createUserProfile(newUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _currentUserRole = null;
    _currentUserId = null;
    await _firebaseAuth.signOut();
    notifyListeners();
  }
}
