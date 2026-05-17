import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/course_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  final CourseService _courseService = CourseService();

  Future<void> _showAddCourseDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final levelController = TextEditingController();

    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  children: [
                    CustomTextField(
                      controller: titleController,
                      label: 'Titre du cours',
                      hintText: 'Ex. Anglais professionnel',
                      prefixIcon: Icons.class_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: levelController,
                      label: 'Niveau',
                      hintText: 'Ex. A1, A2, B1, B2',
                      prefixIcon: Icons.signal_cellular_alt_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hintText: 'Décris le contenu du cours',
                      prefixIcon: Icons.description_rounded,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                    final title = titleController.text.trim();
                    final level = levelController.text.trim();
                    final description =
                    descriptionController.text.trim();

                    if (title.isEmpty ||
                        level.isEmpty ||
                        description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez remplir tous les champs.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      await _courseService.addCourse(
                        title: title,
                        description: description,
                        level: level,
                      );

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cours ajouté avec succès.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => isLoading = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
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
    levelController.dispose();
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
            'Ajoute, consulte et organise tes cours directement depuis ton espace professeur.',
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
                  stream: _courseService.getMyCourses(),
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
                        'Clique sur “Ajouter un cours” pour créer ton premier cours.',
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

                        return _TeacherCourseCard(
                          title: data['title'] ?? 'Sans titre',
                          level: data['level'] ?? '-',
                          students: '${data['studentsCount'] ?? 0} étudiants',
                          nextSession:
                          data['nextSession'] ?? 'Non programmée',
                          description:
                          data['description'] ?? 'Aucune description',
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

class _TeacherCourseCard extends StatelessWidget {
  final String title;
  final String level;
  final String students;
  final String nextSession;
  final String description;

  const _TeacherCourseCard({
    required this.title,
    required this.level,
    required this.students,
    required this.nextSession,
    required this.description,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      students,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.dark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prochaine séance : $nextSession',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
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