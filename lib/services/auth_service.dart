import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

const String kAdminCode = 'UMPHAKATHI-ADMIN-2026';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream auth state changes (login/logout)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Stream the Firestore profile of the current user
  Stream<UserModel?> streamCurrentUser() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(snap.id, snap.data()!);
    });
  }

  // Fetch user once
  Future<UserModel?> getCurrentUserModel() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  /// Register a new community member.
  /// Returns the created UserModel.
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Create Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // 2. Send email verification (optional but nice)
    await cred.user!.sendEmailVerification();

    // 3. Create Firestore profile
    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.member,
      fcmTokens: const [],
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  /// Login with email + password.
  /// Returns the UserModel from Firestore.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      // Auth exists but no profile — shouldn't happen
      await _auth.signOut();
      throw Exception('User profile not found. Please contact support.');
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Register an FCM token for the current user (called after login).
  Future<void> addFcmToken(String token) async {
    final uid = currentUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Remove an FCM token (called on logout).
  Future<void> removeFcmToken(String token) async {
    final uid = currentUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
    /// Register an admin account. Verifies the admin code first.
  /// Throws an exception if the code is wrong.
  Future<UserModel> registerAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String adminCode,
  }) async {
    // 1. Verify admin code
    if (adminCode.trim() != kAdminCode) {
      throw Exception('Invalid admin code');
    }

    // 2. Create Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    await cred.user!.sendEmailVerification();

    // 3. Create Firestore profile with role: admin
    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.admin,
      fcmTokens: const [],
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }
    /// Update the current user's profile fields in Firestore.
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');

    await _db.collection('users').doc(uid).update({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Change the current user's password.
  /// Requires the current password for security.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final email = user.email;
    if (email == null) throw Exception('No email on account');

    // Re-authenticate with current password (Firebase requires this)
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);

    // Then update to the new password
    await user.updatePassword(newPassword);
  }
    // ============================================================
  // WORKER MANAGEMENT (admin-only actions)
  // ============================================================

  /// Creates a worker account WITHOUT logging out the current admin.
  ///
  /// Uses a secondary Firebase app instance so the primary session
  /// (the admin's) stays authenticated. The secondary instance is
  /// disposed immediately after the worker is created.
  Future<UserModel> createWorkerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String temporaryPassword,
  }) async {
    // 1. Ensure admin is actually an admin (defence in depth)
    final adminProfile = await getCurrentUserModel();
    if (adminProfile == null || !adminProfile.isAdmin) {
      throw Exception('Only admins can create worker accounts');
    }

    // 2. Initialize a secondary Firebase app instance (named to avoid clashes)
    const secondaryAppName = 'worker-creation-instance';
    FirebaseApp? secondaryApp;
    try {
      // If it already exists (from a previous invocation), reuse it
      secondaryApp = Firebase.app(secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: Firebase.app().options,
      );
    }

    try {
      // 3. Use the secondary app's auth to create the account
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: temporaryPassword,
      );

      final workerUid = cred.user!.uid;

      // 4. Sign out of the secondary instance (does NOT affect primary)
      await secondaryAuth.signOut();

      // 5. Write the worker's Firestore profile using the PRIMARY Firestore
      //    (the admin is still signed in there, so rules permit it)
      final now = DateTime.now();
      final worker = UserModel(
        uid: workerUid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.worker,
        fcmTokens: const [],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _db.collection('users').doc(workerUid).set(worker.toMap());

      return worker;
    } catch (e) {
      // Re-throw with a clearer message
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw Exception('Failed to create worker account: $e');
    }
    // Note: We deliberately do NOT delete the secondary app — reusing it
    // is faster than reinitializing on every worker creation.
  }

  /// Stream all workers, sorted by first name.
  /// Only admins should call this — Firestore rules will enforce it.
  Stream<List<UserModel>> streamWorkers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .snapshots()
        .map((snap) {
      final workers = snap.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .toList();
      workers.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return workers;
    });
  }

  /// Deactivate a worker account (soft delete — keeps report history intact).
  Future<void> deactivateWorker(String workerId) async {
    final adminProfile = await getCurrentUserModel();
    if (adminProfile == null || !adminProfile.isAdmin) {
      throw Exception('Only admins can deactivate workers');
    }

    await _db.collection('users').doc(workerId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reactivate a worker account.
  Future<void> reactivateWorker(String workerId) async {
    final adminProfile = await getCurrentUserModel();
    if (adminProfile == null || !adminProfile.isAdmin) {
      throw Exception('Only admins can reactivate workers');
    }

    await _db.collection('users').doc(workerId).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
    /// Send a password reset email to any user (worker, member).
  /// The user clicks the emailed link and sets a new password.
  Future<void> sendPasswordResetTo(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}