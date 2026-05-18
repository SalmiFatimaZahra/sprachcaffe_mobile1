import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _coursesCollection {
    return _firestore.collection('courses');
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

    await _coursesCollection.add({
      'title': title,
      'description': description,
      'level': level,
      'teacherId': user.uid,
      'teacherEmail': user.email,
      'studentsCount': 0,
      'nextSession': 'Non programmée',
      'createdAt': FieldValue.serverTimestamp(),
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