import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AdminStats {
  final int usersCount;
  final int studentsCount;
  final int teachersCount;
  final int adminsCount;
  final int paidStudentsCount;
  final int pendingPaymentsCount;
  final int coursesCount;
  final int sessionsCount;
  final int resourcesCount;
  final int assignedStudentsCount;
  final int activeCoursesCount;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> latestUsers;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> latestCourses;

  const AdminStats({
    required this.usersCount,
    required this.studentsCount,
    required this.teachersCount,
    required this.adminsCount,
    required this.paidStudentsCount,
    required this.pendingPaymentsCount,
    required this.coursesCount,
    required this.sessionsCount,
    required this.resourcesCount,
    required this.assignedStudentsCount,
    required this.activeCoursesCount,
    required this.latestUsers,
    required this.latestCourses,
  });
}

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> availableLanguages = [
    'Français',
    'Anglais',
    'Espagnol',
    'Allemand',
    'Italien',
    'Arabe',
  ];

  static const List<String> availableLevels = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _coursesCollection =>
      _firestore.collection('courses');

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _resourcesCollection =>
      _firestore.collection('course_resources');

  CollectionReference<Map<String, dynamic>> get _teacherStudentsCollection =>
      _firestore.collection('teacher_students');

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _usersCollection.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCoursesStream() {
    return _coursesCollection.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSessionsStream() {
    return _sessionsCollection.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getResourcesStream() {
    return _resourcesCollection.snapshots();
  }

  Future<AdminStats> getDashboardStats() async {
    final results = await Future.wait([
      _usersCollection.get(),
      _coursesCollection.get(),
      _sessionsCollection.get(),
      _resourcesCollection.get(),
      _teacherStudentsCollection.get(),
    ]);

    final users = results[0].docs;
    final courses = results[1].docs;
    final sessions = results[2].docs;
    final resources = results[3].docs;
    final teacherStudents = results[4].docs;

    int students = 0;
    int teachers = 0;
    int admins = 0;
    int paidStudents = 0;
    int pendingPayments = 0;

    for (final doc in users) {
      final data = doc.data();
      final role = _cleanText(data['role']).toLowerCase();
      final isPaid = data['isPaid'] == true;
      final paymentStatus = _cleanText(data['paymentStatus']).toLowerCase();

      if (role == 'student') {
        students++;
        if (isPaid) {
          paidStudents++;
        } else if (paymentStatus == 'pending' || paymentStatus.isEmpty) {
          pendingPayments++;
        }
      } else if (role == 'teacher') {
        teachers++;
      } else if (role == 'admin') {
        admins++;
      }
    }

    final latestUsers = [...users]..sort(_sortByCreatedAtDesc);
    final latestCourses = [...courses]..sort(_sortByCreatedAtDesc);

    return AdminStats(
      usersCount: users.length,
      studentsCount: students,
      teachersCount: teachers,
      adminsCount: admins,
      paidStudentsCount: paidStudents,
      pendingPaymentsCount: pendingPayments,
      coursesCount: courses.length,
      sessionsCount: sessions.length,
      resourcesCount: resources.length,
      assignedStudentsCount: teacherStudents.length,
      activeCoursesCount: courses.where((doc) {
        final status = _cleanText(doc.data()['status']).toLowerCase();
        return status.isEmpty || status == 'active' || status == 'actif';
      }).length,
      latestUsers: latestUsers.take(5).toList(),
      latestCourses: latestCourses.take(5).toList(),
    );
  }

  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    String? assignedLanguage,
    List<String> assignedLevels = const [],
  }) async {
    final cleanRole = role.trim().toLowerCase();

    if (cleanRole != 'teacher' && cleanRole != 'admin') {
      throw Exception('Seul un compte prof ou admin peut être créé ici.');
    }

    if (cleanRole == 'teacher') {
      if (_cleanText(assignedLanguage).isEmpty || assignedLevels.isEmpty) {
        throw Exception('Veuillez affecter une langue et au moins un niveau au professeur.');
      }
    }

    const secondaryAppName = 'adminAccountCreator';
    FirebaseApp secondaryApp;

    try {
      secondaryApp = Firebase.app(secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Impossible de créer le compte Firebase Auth.');
    }

    await user.updateDisplayName(name.trim());
    await secondaryAuth.signOut();

    final data = <String, dynamic>{
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': cleanRole,
      'status': 'active',
      'profileCompleted': true,
      'isPaid': true,
      'paymentStatus': 'Not required',
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cleanRole == 'teacher') {
      data.addAll({
        'assignedLanguage': assignedLanguage!.trim(),
        'assignedLevels': assignedLevels,
      });
    }

    await _usersCollection.doc(user.uid).set(data);
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _usersCollection.doc(userId).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    await _usersCollection.doc(userId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateStudentPayment({
    required String userId,
    required bool isPaid,
  }) async {
    await _usersCollection.doc(userId).set({
      'isPaid': isPaid,
      'paymentStatus': isPaid ? 'Paid' : 'Pending',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfileCompleted({
    required String userId,
    required bool profileCompleted,
  }) async {
    await _usersCollection.doc(userId).set({
      'profileCompleted': profileCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTeacherAssignment({
    required String userId,
    required String? assignedLanguage,
    required List<String> assignedLevels,
  }) async {
    await _usersCollection.doc(userId).set({
      'assignedLanguage': assignedLanguage,
      'assignedLevels': assignedLevels,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserDocument(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  Future<void> addCourse({
    required String title,
    required String description,
    required String language,
    required String level,
    String? teacherId,
    String? teacherEmail,
    String? teacherName,
    String? nextSession,
    String status = 'active',
  }) async {
    await _coursesCollection.add({
      'title': title,
      'description': description,
      'language': language,
      'level': level,
      'teacherId': teacherId,
      'teacherEmail': teacherEmail,
      'teacherName': teacherName,
      'studentsCount': 0,
      'nextSession': nextSession?.trim().isNotEmpty == true
          ? nextSession!.trim()
          : 'Non programmée',
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String language,
    required String level,
    String? teacherId,
    String? teacherEmail,
    String? teacherName,
    String? nextSession,
    String status = 'active',
  }) async {
    await _coursesCollection.doc(courseId).set({
      'title': title,
      'description': description,
      'language': language,
      'level': level,
      'teacherId': teacherId,
      'teacherEmail': teacherEmail,
      'teacherName': teacherName,
      'nextSession': nextSession?.trim().isNotEmpty == true
          ? nextSession!.trim()
          : 'Non programmée',
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCourse(String courseId) async {
    await _coursesCollection.doc(courseId).delete();
  }

  static String displayName(Map<String, dynamic> data) {
    final name = _cleanText(data['name']);
    if (name.isNotEmpty) return name;

    final prenom = _cleanText(data['prenom']);
    final nom = _cleanText(data['nom']);
    final fullName = '$prenom $nom'.trim();
    if (fullName.isNotEmpty) return fullName;

    final email = _cleanText(data['email']);
    if (email.isNotEmpty) return email;

    return 'Utilisateur sans nom';
  }

  static String displayEmail(Map<String, dynamic> data) {
    return _cleanText(data['email']).isNotEmpty
        ? _cleanText(data['email'])
        : 'Email non renseigné';
  }

  static List<String> cleanStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => _cleanText(item)).where((item) => item.isNotEmpty).toList();
    }
    final text = _cleanText(value);
    return text.isEmpty ? <String>[] : <String>[text];
  }

  static String _cleanText(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _sortByCreatedAtDesc(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final ad = _extractDate(a.data());
    final bd = _extractDate(b.data());
    return bd.compareTo(ad);
  }

  static DateTime _extractDate(Map<String, dynamic> data) {
    final value = data['createdAt'] ?? data['dateInscription'] ?? data['updatedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
