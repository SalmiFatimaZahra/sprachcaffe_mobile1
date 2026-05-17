import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherPlanningPage extends StatefulWidget {
  const TeacherPlanningPage({super.key});

  @override
  State<TeacherPlanningPage> createState() => _TeacherPlanningPageState();
}

class _TeacherPlanningPageState extends State<TeacherPlanningPage> {
  final SessionService _sessionService = SessionService();

  Future<void> _showAddSessionDialog() async {
    final courseController = TextEditingController();
    final groupController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final roomController = TextEditingController();

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
                'Ajouter une séance',
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
                      controller: courseController,
                      label: 'Cours',
                      hintText: 'Ex. Anglais professionnel',
                      prefixIcon: Icons.class_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: groupController,
                      label: 'Groupe',
                      hintText: 'Ex. Groupe A',
                      prefixIcon: Icons.groups_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: dateController,
                      label: 'Date',
                      hintText: 'Ex. 2026-05-20',
                      prefixIcon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: timeController,
                      label: 'Horaire',
                      hintText: 'Ex. 18:30 - 20:00',
                      prefixIcon: Icons.access_time_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: roomController,
                      label: 'Salle',
                      hintText: 'Ex. Salle 204',
                      prefixIcon: Icons.meeting_room_rounded,
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
                    final course = courseController.text.trim();
                    final group = groupController.text.trim();
                    final date = dateController.text.trim();
                    final time = timeController.text.trim();
                    final room = roomController.text.trim();

                    if (course.isEmpty ||
                        group.isEmpty ||
                        date.isEmpty ||
                        time.isEmpty ||
                        room.isEmpty) {
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
                      await _sessionService.addSession(
                        courseTitle: course,
                        groupName: group,
                        date: date,
                        time: time,
                        room: room,
                      );

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Séance ajoutée avec succès.'),
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

    courseController.dispose();
    groupController.dispose();
    dateController.dispose();
    timeController.dispose();
    roomController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Planning',
            title: 'Mes séances',
            subtitle:
            'Ajoute et consulte tes séances directement depuis Firebase.',
            icon: Icons.calendar_month_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  label: 'Ajouter une séance',
                  icon: Icons.add_rounded,
                  onPressed: _showAddSessionDialog,
                ),
                const SizedBox(height: 24),
                const SectionTitle('Séances programmées'),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _sessionService.getMySessions(),
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
                      return _EmptySessionsBox(
                        title: 'Erreur de chargement',
                        subtitle: snapshot.error.toString(),
                        icon: Icons.error_outline_rounded,
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const _EmptySessionsBox(
                        title: 'Aucune séance pour le moment',
                        subtitle:
                        'Clique sur “Ajouter une séance” pour programmer ton premier cours.',
                        icon: Icons.event_busy_rounded,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();

                        return _SessionCard(
                          course: data['courseTitle'] ?? 'Cours sans titre',
                          group: data['groupName'] ?? 'Groupe non défini',
                          date: data['date'] ?? 'Date non définie',
                          time: data['time'] ?? 'Horaire non défini',
                          room: data['room'] ?? 'Salle non définie',
                          status: data['status'] ?? 'upcoming',
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

class _EmptySessionsBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptySessionsBox({
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

class _SessionCard extends StatelessWidget {
  final String course;
  final String group;
  final String date;
  final String time;
  final String room;
  final String status;

  const _SessionCard({
    required this.course,
    required this.group,
    required this.date,
    required this.time,
    required this.room,
    required this.status,
  });

  String get statusLabel {
    if (status == 'done') return 'Terminée';
    if (status == 'today') return 'Aujourd’hui';
    return 'À venir';
  }

  bool get isToday => status == 'today';
  bool get isDone => status == 'done';

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
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      group,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: statusLabel,
                isToday: isToday,
                isDone: isDone,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoLine(
            icon: Icons.calendar_today_rounded,
            label: date,
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.access_time_rounded,
            label: time,
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.meeting_room_rounded,
            label: room,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.mutedText,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isToday;
  final bool isDone;

  const _StatusBadge({
    required this.label,
    required this.isToday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary
            : isDone
            ? AppColors.background
            : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.dark,
        ),
      ),
    );
  }
}