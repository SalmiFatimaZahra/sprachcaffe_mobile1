import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../services/resource_service.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentResourcesPage extends StatefulWidget {
  const StudentResourcesPage({super.key});

  @override
  State<StudentResourcesPage> createState() => _StudentResourcesPageState();
}

class _StudentResourcesPageState extends State<StudentResourcesPage> {
  final ResourceService _resourceService = ResourceService();

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _resourcesFuture;

  @override
  void initState() {
    super.initState();
    _resourcesFuture = _resourceService.getResourcesForCurrentStudent();
  }

  Future<void> _refreshResources() async {
    setState(() {
      _resourcesFuture = _resourceService.getResourcesForCurrentStudent();
    });
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
    return RefreshIndicator(
      onRefresh: _refreshResources,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const PremiumHeader(
              badge: 'Ressources',
              title: 'Bibliothèque pédagogique',
              subtitle:
              'Consulte seulement les PDF liés à tes cours.',
              icon: Icons.folder_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Mes documents'),
                  const SizedBox(height: 14),
                  FutureBuilder<
                      List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                    future: _resourcesFuture,
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
                        return _EmptyStudentResourcesBox(
                          title: 'Erreur de chargement',
                          subtitle: snapshot.error.toString(),
                          icon: Icons.error_outline_rounded,
                        );
                      }

                      final docs = snapshot.data ?? [];

                      if (docs.isEmpty) {
                        return const _EmptyStudentResourcesBox(
                          title: 'Aucune ressource disponible',
                          subtitle:
                          'Tu verras ici les documents des cours auxquels ton professeur t’a ajouté.',
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

                          return _StudentResourceCard(
                            title: data['title'] ?? 'Sans titre',
                            description:
                            data['description'] ?? 'Aucune description',
                            courseTitle:
                            data['courseTitle'] ?? 'Cours non défini',
                            fileName: data['fileName'] ?? 'document.pdf',
                            onOpen: () {
                              final url = data['fileUrl'] ?? '';

                              if (url.toString().isNotEmpty) {
                                _openResource(url.toString());
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
      ),
    );
  }
}

class _EmptyStudentResourcesBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyStudentResourcesBox({
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

class _StudentResourceCard extends StatelessWidget {
  final String title;
  final String description;
  final String courseTitle;
  final String fileName;
  final VoidCallback onOpen;

  const _StudentResourceCard({
    required this.title,
    required this.description,
    required this.courseTitle,
    required this.fileName,
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