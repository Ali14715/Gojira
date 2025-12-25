import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ======================
  // REGISTER
  // ======================
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('REGISTER START');

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      print('AUTH CREATED UID: $uid');

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      print('FIRESTORE USER SAVED');

      await _auth.signOut();
      print('LOGOUT SUCCESS');
    } catch (e, s) {
      print('REGISTER ERROR: $e');
      print(s);
      rethrow;
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Ensure profile fields like displayName are up-to-date.
    await cred.user?.reload();
  }

  // GET PROFILE
  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await user.reload();
    final freshUser = currentUser!;
    final docRef = _firestore.collection('users').doc(freshUser.uid);

    var snap = await docRef.get();

    // ✅ HANYA AUTO-CREATE JIKA AKUN LAMA
    if (!snap.exists) {
      final displayName = (freshUser.displayName ?? '').trim();

      await docRef.set({
        'email': freshUser.email ?? '',
        'createdAt': Timestamp.now(),
        if (displayName.isNotEmpty) 'name': displayName,
      });

      snap = await docRef.get();
    }

    return snap;
  }

  // UPDATE PROFILE
  Future<void> updateName({
    required String name,
    String? phone,
    String? imageUrl,
    DateTime? birthDate,
    String? gender,
  }) async {
    final data = <String, dynamic>{'name': name};

    if (phone != null) data['phone'] = phone;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (birthDate != null) {
      data['birthDate'] = birthDate.toIso8601String();
    }
    if (gender != null) data['gender'] = gender;

    await _firestore.collection('users').doc(currentUser!.uid).update(data);
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _auth.signOut();
  }
}
