import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pour écouter l'état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Connexion
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Inscription
  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Mettre à jour le nom
    await credential.user?.updateDisplayName(name);

    // Créer le document utilisateur dans Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'id': credential.user!.uid,
      'name': name,
      'email': email,
      'role': 'client', // rôle par défaut
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mot de passe oublié
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Récupérer le rôle de l'utilisateur
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'client';
  }
}