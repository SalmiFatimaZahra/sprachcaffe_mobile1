import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCollection {
    return _firestore.collection('sessions');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMySessions() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _sessionsCollection
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> addSession({
    required String courseId,
    required String courseTitle,
    required String groupName,
    required String date,
    required String time,
    required String room,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    await _sessionsCollection.add({
      'courseId': courseId,
      'courseTitle': courseTitle,
      'groupName': groupName,
      'date': date,
      'time': time,
      'room': room,
      'status': 'upcoming',
      'teacherId': user.uid,
      'teacherEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getMySessionsCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 0;
    }

    final snapshot = await _sessionsCollection
        .where('teacherId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length;
  }
}