import 'package:flutter/material.dart';

import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ManageCoursesPage extends StatelessWidget {
  const ManageCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Gestion des cours',
            title: 'Catalogue de formation',
            subtitle: 'Prépare ici la gestion future des programmes, tarifs, affectations et capacités.',
            icon: Icons.book_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionTitle('Cours configurés'),
                SizedBox(height: 14),
                CourseCard(
                  title: 'Anglais professionnel',
                  subtitle: 'Programme entreprise avec suivi multi-groupes.',
                  badge: 'Fort trafic',
                  schedule: '3 groupes actifs',
                  icon: Icons.business_center_rounded,
                ),
                SizedBox(height: 12),
                CourseCard(
                  title: 'Français conversation',
                  subtitle: 'Ateliers oraux pour fluidité et confiance.',
                  badge: 'Populaire',
                  schedule: '2 créneaux / semaine',
                  icon: Icons.record_voice_over_rounded,
                ),
                SizedBox(height: 12),
                CourseCard(
                  title: 'Préparation TOEIC',
                  subtitle: 'Parcours intensif orienté certification.',
                  badge: 'Certifiant',
                  schedule: 'Sessions mensuelles',
                  icon: Icons.workspace_premium_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
