import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  CollectionReference<Map<String, dynamic>> get _resourcesCollection {
    return _firestore.collection('course_resources');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyResources() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _resourcesCollection
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getResourcesByCourse(
      String courseId,
      ) {
    return _resourcesCollection
        .where('courseId', isEqualTo: courseId)
        .snapshots();
  }

  Future<void> addPdfResource({
    required String courseId,
    required String courseTitle,
    required String title,
    required String description,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('Aucun fichier sélectionné.');
    }

    final pickedFile = result.files.single;
    final file = File(pickedFile.path!);

    final safeFileName = pickedFile.name.replaceAll(' ', '_');

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    final filePath = '$courseId/$fileName';

    await _supabase.storage.from('course-resources').upload(
      filePath,
      file,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );

    final fileUrl = _supabase.storage
        .from('course-resources')
        .getPublicUrl(filePath);

    await _resourcesCollection.add({
      'courseId': courseId,
      'courseTitle': courseTitle,
      'teacherId': user.uid,
      'teacherEmail': user.email,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': pickedFile.name,
      'fileType': 'pdf',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}