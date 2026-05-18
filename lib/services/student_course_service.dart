import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentCourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _teacherStudentsCollection {
    return _firestore.collection('teacher_students');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getMyCoursesAsStudent() async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      return [];
    }

    final studentEmail = user.email!.trim().toLowerCase();

    final snapshot = await _teacherStudentsCollection
        .where('studentEmail', isEqualTo: studentEmail)
        .get();

    return snapshot.docs;
  }
}