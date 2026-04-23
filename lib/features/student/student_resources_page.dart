import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentResourcesPage extends StatelessWidget {
  const StudentResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const resources = [
      {
        'type': 'PDF',
        'title': 'Guide de grammaire anglaise',
        'meta': 'Téléchargement direct',
      },
      {
        'type': 'Vidéo',
        'title': 'Prononciation niveau B1',
        'meta': '12 min',
      },
      {
        'type': 'Exercice',
        'title': 'Quiz expression écrite',
        'meta': 'Auto-correction',
      },
      {
        'type': 'Podcast',
        'title': 'Conversation du quotidien',
        'meta': 'Écoute guidée',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Ressources',
            title: 'Bibliothèque pédagogique',
            subtitle: 'Documents, vidéos, audios et exercices accessibles selon tes cours et ton niveau.',
            icon: Icons.folder_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ressource',
                    prefixIcon: Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Disponibles maintenant'),
                const SizedBox(height: 14),
                ...resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResourceTile(
                      type: resource['type']!,
                      title: resource['title']!,
                      meta: resource['meta']!,
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

class _ResourceTile extends StatelessWidget {
  final String type;
  final String title;
  final String meta;

  const _ResourceTile({
    required this.type,
    required this.title,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Text(
          type,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
      ),
      subtitle: Text(
        meta,
        style: const TextStyle(
          color: AppColors.mutedText,
        ),
      ),
      trailing: const Icon(Icons.download_rounded, color: AppColors.dark),
    );
  }
}
