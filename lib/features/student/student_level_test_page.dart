import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentLevelTestPage extends StatelessWidget {
  const StudentLevelTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    const questions = [
      'Comprendre une consigne simple à l’écrit',
      'Tenir une conversation courte en autonomie',
      'Rédiger un message professionnel simple',
      'Comprendre une vidéo courte sans sous-titres',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de niveau'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PremiumHeader(
              badge: 'Évaluation',
              title: 'Positionnement linguistique',
              subtitle: 'Structure prête à accueillir plus tard un vrai questionnaire, un scoring et des résultats dynamiques.',
              icon: Icons.quiz_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Aperçu des compétences'),
                  const SizedBox(height: 14),
                  ...questions.map(
                    (item) => CheckboxListTile(
                      value: true,
                      onChanged: (_) {},
                      tileColor: Colors.white,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      title: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Voir mon estimation',
                    icon: Icons.insights_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exemple de résultat : niveau estimé B1.'),
                        ),
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
