import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The FirebaseAuth singleton, exposed as a provider so tests can override it.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Streams the current signed-in [User] (or null). This is the reactive source
/// of truth the router's redirect uses to gate the app behind sign-in.
///
/// `authStateChanges()` is a [Stream] — another natural Stream use case: auth
/// state changes over time (sign in, sign out, token refresh).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// App-facing sign-in status, decoupled from Firebase's `User` type so the
/// router (and tests) depend on a simple `AsyncValue<bool>` instead of having
/// to fake FirebaseAuth. Loading while the first auth state resolves.
final isAuthenticatedProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(authStateProvider).whenData((user) => user != null);
});

/// Thin controller over the auth actions the UI needs.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider));
});

class AuthController {
  AuthController(this._auth);
  final FirebaseAuth _auth;

  Future<void> signInAnonymously() => _auth.signInAnonymously();

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();
}
