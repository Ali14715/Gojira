import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // =========================
  // REGISTER
  // =========================
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    AppUser user = AppUser(
      uid: cred.user!.uid,
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    // Sign out immediately so the user must login after registration.
    // This prevents automatic login on createUserWithEmailAndPassword.
    await _auth.signOut();
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // GET PROFILE
  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    var snap = await docRef.get();

    // If profile document doesn't exist yet (e.g. old accounts), create it.
    if (!snap.exists || snap.data() == null) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      );
      await docRef.set(appUser.toMap());
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
