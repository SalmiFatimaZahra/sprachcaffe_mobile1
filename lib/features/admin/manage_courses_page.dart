import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final AdminService _adminService = AdminService();

  Future<void> _openCourseDialog({
    QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc,
  }) async {
    final courseData = courseDoc?.data() ?? <String, dynamic>{};
    final titleController = TextEditingController(text: _text(courseData['title']));
    final descriptionController = TextEditingController(text: _text(courseData['description']));
    final levelController = TextEditingController(text: _text(courseData['level']));
    final nextSessionController = TextEditingController(
      text: _text(courseData['nextSession']) == 'Non programmée'
          ? ''
          : _text(courseData['nextSession']),
    );

    String? selectedTeacherId = _emptyToNull(courseData['teacherId']);
    String? selectedTeacherEmail = _emptyToNull(courseData['teacherEmail']);
    String? selectedTeacherName = _emptyToNull(courseData['teacherName']);
    String status = _normalizeStatus(courseData['status']);
    bool isLoading = false;

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                courseDoc == null ? 'Ajouter un cours' : 'Modifier le cours',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: titleController,
                        label: 'Titre du cours',
                        hintText: 'Ex. Anglais professionnel',
                        prefixIcon: Icons.menu_book_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hintText: 'Objectif et contenu du cours',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: levelController,
                        label: 'Niveau',
                        hintText: 'Ex. A1, A2, B1, B2, C1',
                        prefixIcon: Icons.signal_cellular_alt_rounded,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: nextSessionController,
                        label: 'Prochaine séance',
                        hintText: 'Ex. Lundi 18:00 - Salle 2',
                        prefixIcon: Icons.event_rounded,
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _adminService.getUsersStream(),
                        builder: (context, snapshot) {
                          final teachers = (snapshot.data?.docs ?? [])
                              .where((doc) => _text(doc.data()['role']).toLowerCase() == 'teacher')
                              .toList();

                          final teacherIds = teachers.map((doc) => doc.id).toSet();
                          final value = teacherIds.contains(selectedTeacherId)
                              ? selectedTeacherId
                              : null;

                          return DropdownButtonFormField<String>(
                            value: value,
                            decoration: _inputDecoration(
                              'Professeur affecté',
                              Icons.co_present_rounded,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'none',
                                child: Text('Aucun professeur'),
                              ),
                              ...teachers.map((doc) {
                                final data = doc.data();
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    '${AdminService.displayName(data)} - ${AdminService.displayEmail(data)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: isLoading
                                ? null
                                : (value) {
                              if (value == null || value == 'none') {
                                setDialogState(() {
                                  selectedTeacherId = null;
                                  selectedTeacherEmail = null;
                                  selectedTeacherName = null;
                                });
                                return;
                              }

                              final teacherDoc = teachers.firstWhere((doc) => doc.id == value);
                              final data = teacherDoc.data();

                              setDialogState(() {
                                selectedTeacherId = teacherDoc.id;
                                selectedTeacherEmail = AdminService.displayEmail(data);
                                selectedTeacherName = AdminService.displayName(data);
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: _inputDecoration('Statut', Icons.verified_rounded),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Actif')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                          DropdownMenuItem(value: 'archived', child: Text('Archivé')),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) {
                          if (value == null) return;
                          setDialogState(() => status = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: Text(isLoading ? 'Enregistrement...' : 'Enregistrer'),
                  onPressed: isLoading
                      ? null
                      : () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();
                    final level = levelController.text.trim();

                    if (title.isEmpty || description.isEmpty || level.isEmpty) {
                      _showMessage('Veuillez remplir le titre, la description et le niveau.');
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      if (courseDoc == null) {
                        await _adminService.addCourse(
                          title: title,
                          description: description,
                          level: level,
                          teacherId: selectedTeacherId,
                          teacherEmail: selectedTeacherEmail,
                          teacherName: selectedTeacherName,
                          nextSession: nextSessionController.text,
                          status: status,
                        );
                      } else {
                        await _adminService.updateCourse(
                          courseId: courseDoc.id,
                          title: title,
                          description: description,
                          level: level,
                          teacherId: selectedTeacherId,
                          teacherEmail: selectedTeacherEmail,
                          teacherName: selectedTeacherName,
                          nextSession: nextSessionController.text,
                          status: status,
                        );
                      }

                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      _showMessage('Erreur: $e');
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() => isLoading = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    levelController.dispose();
    nextSessionController.dispose();

    if (saved == true) {
      _showMessage(courseDoc == null ? 'Cours ajouté.' : 'Cours modifié.');
    }
  }

  Future<void> _deleteCourse(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Supprimer "${_text(doc.data()['title'])}" du catalogue ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteCourse(doc.id);
      _showMessage('Cours supprimé.');
    } catch (e) {
      _showMessage('Erreur: $e');
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _adminService.getCoursesStream(),
      builder: (context, snapshot) {
        final courses = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          child: Column(
            children: [
              PremiumHeader(
                badge: 'Gestion des cours',
                title: 'Catalogue de formation',
                subtitle:
                'Créer, modifier, affecter à un professeur, activer ou supprimer les cours du centre.',
                icon: Icons.book_rounded,
                bottom: CustomButton(
                  label: 'Ajouter un cours',
                  icon: Icons.add_rounded,
                  onPressed: () => _openCourseDialog(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('Cours configurés (${courses.length})'),
                    const SizedBox(height: 14),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (snapshot.hasError)
                      const _InfoBox(
                        text: 'Erreur de chargement des cours.',
                        danger: true,
                      )
                    else if (courses.isEmpty)
                        const _InfoBox(
                          text: 'Aucun cours pour le moment. Clique sur Ajouter un cours.',
                        )
                      else
                        ...courses.map((doc) {
                          final data = doc.data();
                          final title = _text(data['title']).isEmpty
                              ? 'Cours sans titre'
                              : _text(data['title']);
                          final description = _text(data['description']).isEmpty
                              ? 'Aucune description.'
                              : _text(data['description']);
                          final level = _text(data['level']).isEmpty
                              ? 'Niveau non défini'
                              : _text(data['level']);
                          final status = _normalizeStatus(data['status']);
                          final teacher = _text(data['teacherName']).isNotEmpty
                              ? _text(data['teacherName'])
                              : _text(data['teacherEmail']).isNotEmpty
                              ? _text(data['teacherEmail'])
                              : 'Prof non affecté';
                          final nextSession = _text(data['nextSession']).isEmpty
                              ? 'Non programmée'
                              : _text(data['nextSession']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primarySoft,
                                      child: Icon(
                                        status == 'active'
                                            ? Icons.menu_book_rounded
                                            : Icons.archive_outlined,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              color: AppColors.mutedText,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _Badge(text: level),
                                    _Badge(text: status == 'active' ? 'Actif' : status),
                                    _Badge(text: teacher),
                                    _Badge(text: nextSession),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openCourseDialog(courseDoc: doc),
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Modifier'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _deleteCourse(doc),
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        label: const Text('Supprimer'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.dark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool danger;

  const _InfoBox({required this.text, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: danger ? Colors.red.shade100 : AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: danger ? Colors.red.shade800 : AppColors.mutedText,
          fontWeight: danger ? FontWeight.w800 : FontWeight.w500,
        ),
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

String? _emptyToNull(dynamic value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

String _normalizeStatus(dynamic status) {
  final value = _text(status).toLowerCase();
  if (value == 'inactive' || value == 'archived' || value == 'active') {
    return value;
  }
  if (value == 'actif') return 'active';
  return 'active';
}
