import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
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

  Future<_TeacherAssignment> _loadTeacherAssignment() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final doc = await _usersCollection.doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    return _TeacherAssignment(
      language: _text(data['assignedLanguage']),
      levels: AdminService.cleanStringList(data['assignedLevels']),
    );
  }

  Future<void> _addCourse({
    required String title,
    required String description,
    required String language,
    required String level,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
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

  Future<void> _showAddCourseDialog() async {
    late final _TeacherAssignment assignment;

    try {
      assignment = await _loadTeacherAssignment();
    } catch (e) {
      _showMessage('Erreur: $e');
      return;
    }

    if (assignment.language.isEmpty || assignment.levels.isEmpty) {
      _showMessage('Aucune langue/niveau affecté. Demande à l’admin de configurer ton compte.');
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedLevel = assignment.levels.first;

    bool isLoading = false;

    final bool? added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Ajouter un cours',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex. Anglais professionnel',
                        prefixIcon: const Icon(Icons.title_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décris le contenu du cours',
                        prefixIcon: const Icon(Icons.description_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, color: AppColors.dark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Langue affectée par l’admin : ${assignment.language}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: _inputDecoration('Niveau autorisé', Icons.signal_cellular_alt_rounded),
                      items: assignment.levels
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() => selectedLevel = value);
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();

                          if (title.isEmpty || description.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez remplir le titre et la description.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            await _addCourse(
                              title: title,
                              description: description,
                              language: assignment.language,
                              level: selectedLevel,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLoading = false);

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isLoading ? 'Ajout...' : 'Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (!mounted) return;

    if (added == true) {
      _showMessage('Cours ajouté avec succès.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Mes cours',
            title: 'Gérer mes classes',
            subtitle:
                'La langue est définie par l’admin. Tu choisis seulement un niveau parmi les niveaux autorisés.',
            icon: Icons.class_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  label: 'Ajouter un cours',
                  icon: Icons.add_rounded,
                  onPressed: _showAddCourseDialog,
                ),
                const SizedBox(height: 24),
                const SectionTitle('Cours actifs'),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: getMyCourses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _EmptyCoursesBox(
                        title: 'Erreur de chargement',
                        subtitle: snapshot.error.toString(),
                        icon: Icons.error_outline_rounded,
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const _EmptyCoursesBox(
                        title: 'Aucun cours pour le moment',
                        subtitle:
                            'Clique sur “Ajouter un cours” pour créer ta première classe.',
                        icon: Icons.class_outlined,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();

                        return _CourseCard(
                          title: _text(data['title']).isEmpty ? 'Cours sans titre' : _text(data['title']),
                          description: _text(data['description']).isEmpty ? 'Aucune description' : _text(data['description']),
                          language: _text(data['language']).isEmpty ? 'Langue non définie' : _text(data['language']),
                          level: _text(data['level']).isEmpty ? '-' : _text(data['level']),
                          studentsCount: data['studentsCount'] is int ? data['studentsCount'] : 0,
                          nextSession: _text(data['nextSession']).isEmpty ? 'Non programmée' : _text(data['nextSession']),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAssignment {
  final String language;
  final List<String> levels;

  const _TeacherAssignment({
    required this.language,
    required this.levels,
  });
}

class _EmptyCoursesBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyCoursesBox({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              icon,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.4,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final String language;
  final String level;
  final int studentsCount;
  final String nextSession;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.language,
    required this.level,
    required this.studentsCount,
    required this.nextSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  level,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$language • $studentsCount étudiants',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              height: 1.45,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: AppColors.dark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prochaine séance : $nextSession',
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.mutedText),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );
}

String _text(dynamic value) => value?.toString().trim() ?? '';
