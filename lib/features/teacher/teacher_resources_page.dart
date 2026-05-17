import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../services/course_service.dart';
import '../../services/resource_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherResourcesPage extends StatefulWidget {
  const TeacherResourcesPage({super.key});

  @override
  State<TeacherResourcesPage> createState() => _TeacherResourcesPageState();
}

class _TeacherResourcesPageState extends State<TeacherResourcesPage> {
  final ResourceService _resourceService = ResourceService();
  final CourseService _courseService = CourseService();

  Future<void> _showAddResourceDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String? selectedCourseId;
    String? selectedCourseTitle;
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
                'Déposer un document',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _courseService.getMyCourses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Erreur de chargement des cours.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }

                        final courses = snapshot.data?.docs ?? [];

                        if (courses.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Aucun cours trouvé. Ajoute d’abord un cours dans la page Classes.',
                              style: TextStyle(
                                height: 1.4,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedCourseId,
                          decoration: InputDecoration(
                            labelText: 'Cours',
                            prefixIcon: const Icon(
                              Icons.class_rounded,
                              color: AppColors.mutedText,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                          items: courses.map((doc) {
                            final data = doc.data();
                            final title = data['title'] ?? 'Cours sans titre';

                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(title),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) {
                            if (value == null) return;

                            final selectedDoc = courses.firstWhere(
                                  (doc) => doc.id == value,
                            );

                            final data = selectedDoc.data();

                            setDialogState(() {
                              selectedCourseId = selectedDoc.id;
                              selectedCourseTitle =
                                  data['title'] ?? 'Cours sans titre';
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: titleController,
                      label: 'Titre',
                      hintText: 'Ex. Cours 1 - Introduction',
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hintText: 'Décris le contenu du document',
                      prefixIcon: Icons.description_rounded,
                      maxLines: 3,
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.dark,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Après avoir cliqué sur Ajouter, le sélecteur de fichiers PDF va s’ouvrir.',
                              style: TextStyle(
                                height: 1.4,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    final description =
                    descriptionController.text.trim();

                    if (selectedCourseId == null ||
                        selectedCourseTitle == null ||
                        title.isEmpty ||
                        description.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner un cours et remplir tous les champs.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    FocusScope.of(dialogContext).unfocus();

                    await Future.delayed(
                      const Duration(milliseconds: 600),
                    );

                    if (!dialogContext.mounted) return;

                    setDialogState(() => isLoading = true);

                    try {
                      await _resourceService.addPdfResource(
                        courseId: selectedCourseId!,
                        courseTitle: selectedCourseTitle!,
                        title: title,
                        description: description,
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
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(isLoading ? 'Envoi...' : 'Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document ajouté avec succès.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir le document.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Ressources',
            title: 'Documents de cours',
            subtitle:
            'Dépose des PDF et supports pédagogiques pour tes étudiants.',
            icon: Icons.folder_copy_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  label: 'Déposer un PDF',
                  icon: Icons.upload_file_rounded,
                  onPressed: _showAddResourceDialog,
                ),
                const SizedBox(height: 24),
                const SectionTitle('Mes ressources'),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _resourceService.getMyResources(),
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
                      return _EmptyResourcesBox(
                        title: 'Erreur de chargement',
                        subtitle: snapshot.error.toString(),
                        icon: Icons.error_outline_rounded,
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const _EmptyResourcesBox(
                        title: 'Aucune ressource pour le moment',
                        subtitle:
                        'Clique sur “Déposer un PDF” pour ajouter un support de cours.',
                        icon: Icons.folder_off_rounded,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();

                        return _ResourceCard(
                          title: data['title'] ?? 'Sans titre',
                          description:
                          data['description'] ?? 'Aucune description',
                          courseTitle:
                          data['courseTitle'] ?? 'Cours non défini',
                          fileName: data['fileName'] ?? 'document.pdf',
                          fileUrl: data['fileUrl'] ?? '',
                          onOpen: () {
                            final url = data['fileUrl'] ?? '';

                            if (url.isNotEmpty) {
                              _openResource(url);
                            }
                          },
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

class _EmptyResourcesBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyResourcesBox({
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

class _ResourceCard extends StatelessWidget {
  final String title;
  final String description;
  final String courseTitle;
  final String fileName;
  final String fileUrl;
  final VoidCallback onOpen;

  const _ResourceCard({
    required this.title,
    required this.description,
    required this.courseTitle,
    required this.fileName,
    required this.fileUrl,
    required this.onOpen,
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
                radius: 25,
                backgroundColor: AppColors.primarySoft,
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.dark,
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
                      courseTitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: AppColors.dark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Ouvrir le PDF'),
            ),
          ),
        ],
      ),
    );
  }
}