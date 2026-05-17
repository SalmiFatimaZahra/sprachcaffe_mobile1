import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _teacherStudentsCollection {
    return _firestore.collection('teacher_students');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyStudents() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _teacherStudentsCollection
        .where('teacherId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addStudent({
    required String studentName,
    required String studentEmail,
    required String level,
    required String courseTitle,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    await _teacherStudentsCollection.add({
      'teacherId': user.uid,
      'teacherEmail': user.email,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'level': level,
      'progress': 0,
      'status': 'Nouveau',
      'courseTitle': courseTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getMyStudentsCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 0;
    }

    final snapshot = await _teacherStudentsCollection
        .where('teacherId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length;
  }
}