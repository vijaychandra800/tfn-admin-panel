import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../providers/auth_state_provider.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  Future<UserCredential?> createAuthor(String email, String password) async {
    UserCredential? userCredential;
    FirebaseApp app = await Firebase.initializeApp(
      name: 'Temp',
      options: Firebase.app().options,
    );

    try {
      userCredential = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      debugPrint('error on creating author account: $error');
      // Do something with exception. This try/catch is here to make sure
      // that even if the user creation fails, app.delete() runs, if is not,
      // next time Firebase.initializeApp() will fail as the previous one was
      // not deleted.
    }

    await app.delete();
    return userCredential;
  }

  Future<UserCredential?> loginWithEmailPassword(String email, String password) async {
    UserCredential? userCredential;
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password).then((UserCredential user) async {
      userCredential = user;
    }).catchError((e) {
      debugPrint('SignIn Error: $e');
    });

    return userCredential;
  }

  Future loginAnnonumously() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future adminLogout() async {
    return _firebaseAuth.signOut().then((value) {
      debugPrint('Logout Success');
    }).catchError((e) {
      debugPrint('Logout error: $e');
    });
  }

  Future<UserRoles> checkUserRole(String uid) async {
    UserRoles authState = UserRoles.none;
    print(uid);
    await _firebaseFirestore.collection('users').doc(uid).get().then((DocumentSnapshot snap) {
      if (snap.exists) {
        List? userRole = snap['role'];
        debugPrint('User Role: $userRole');
        if (userRole != null) {
          if (userRole.contains('admin')) {
            authState = UserRoles.admin;
          } else if (userRole.contains('author')) {
            authState = UserRoles.author;
          }
        }
      }
    }).catchError((e) {
      debugPrint('check access error: $e');
    });
    return authState;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    bool success = false;
    final user = _firebaseAuth.currentUser;
    final cred = EmailAuthProvider.credential(email: user!.email!, password: oldPassword);
    await user.reauthenticateWithCredential(cred).then((UserCredential? userCredential) async {
      if (userCredential != null) {
        await user.updatePassword(newPassword).then((_) {
          success = true;
        }).catchError((error) {
          debugPrint(error);
          success = false;
        });
      } else {
        success = false;
        debugPrint('Reauthentication failed');
      }
    }).catchError((err) {
      debugPrint('errro: $err');
      success = false;
    });

    return success;
  }
}
