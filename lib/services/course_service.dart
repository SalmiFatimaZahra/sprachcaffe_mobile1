import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_service.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _coursesCollection {
    return _firestore.collection('courses');
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyCourses() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _coursesCollection
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> addCourse({
    required String title,
    required String description,
    required String level,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final teacherDoc = await _usersCollection.doc(user.uid).get();
    final teacherData = teacherDoc.data() ?? <String, dynamic>{};
    final language = teacherData['assignedLanguage']?.toString().trim() ?? '';
    final levels = AdminService.cleanStringList(teacherData['assignedLevels']);

    if (language.isEmpty || !levels.contains(level)) {
      throw Exception('Ce niveau n’est pas autorisé pour ce professeur.');
    }

    await _coursesCollection.add({
      'title': title,
      'description': description,
      'language': language,
      'level': level,
      'teacherId': user.uid,
      'teacherEmail': user.email,
      'teacherName': user.displayName,
      'studentsCount': 0,
      'nextSession': 'Non programmée',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getMyCoursesCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 0;
    }

    final snapshot = await _coursesCollection
        .where('teacherId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length;
  }
}
