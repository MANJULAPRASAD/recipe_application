import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore App ID
  final String _appId = "recipe-app-13701d";

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Log In
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'This email is not registered.';
      } else if (e.code == 'wrong-password') {
        throw 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        throw 'Please enter a valid email address.';
      } else {
        throw e.message ?? 'An error occurred during log in.';
      }
    } catch (e) {
      throw 'A system error occurred. Please try again later.';
    }
  }

  // Sign Up
  Future<UserCredential?> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final User? user = userCredential.user;
      if (user != null) {
        await _firestore
            .collection('artifacts')
            .doc(_appId)
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('info')
            .set({
              'uid': user.uid,
              'name': name.trim(),
              'email': email.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password is too weak (must be at least 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        throw 'This email is already in use.';
      } else {
        throw e.message ?? 'An error occurred during registration.';
      }
    } catch (e) {
      throw 'A system error occurred.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Profile Error: $e");
      return null;
    }
  }

  // 💡 [UPDATED] Firestore හි නම, ආහාර රටාව සහ Avatar එක එකවර යාවත්කාලීන කිරීමේ හැකියාව
  Future<void> updateUserProfile(
    String userId, {
    required String newName,
    String? dietPreference,
    String? avatarIndex,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'name': newName.trim()};

      if (dietPreference != null) {
        updateData['dietPreference'] = dietPreference;
      }
      if (avatarIndex != null) {
        updateData['avatarIndex'] = avatarIndex;
      }

      await _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .update(updateData);
    } catch (e) {
      throw 'Could not update profile information. Please try again.';
    }
  }
}
