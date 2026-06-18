// FIX_V3: formulaire de création sans TextEditingController local.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedRoleFilter = 'all';
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    return docs.where((doc) {
      final data = doc.data();
      final role = _text(data['role']).toLowerCase();
      final name = AdminService.displayName(data).toLowerCase();
      final email = AdminService.displayEmail(data).toLowerCase();
      final search = _search.trim().toLowerCase();

      final roleOk = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;
      final searchOk = search.isEmpty || name.contains(search) || email.contains(search);

      return roleOk && searchOk;
    }).toList();
  }

  Future<void> _openCreateStaffDialog() async {
    debugPrint('[ManageUsers] FIX_V3 dialog opened');
    final bool? created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateStaffDialog(adminService: _adminService),
    );

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _searchController.clear();
        _search = '';
        _selectedRoleFilter = 'all';
      });

      _showMessage('Compte créé avec succès. Il apparaît maintenant dans la liste.');
    }
  }

  Future<void> _openUserActions(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final data = doc.data();
    final originalRole = _normalizeRole(data['role']);
    String role = originalRole;
    String status = _normalizeStatus(data['status']);
    bool isPaid = data['isPaid'] == true;
    bool profileCompleted = data['profileCompleted'] == true;
    String? assignedLanguage = _emptyToNull(data['assignedLanguage']) ?? AdminService.availableLanguages.first;
    final assignedLevels = AdminService.cleanStringList(data['assignedLevels']).toSet();
    bool isLoading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AdminService.displayName(data),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AdminService.displayEmail(data),
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 22),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: _inputDecoration('Rôle', Icons.badge_rounded),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Étudiant')),
                        DropdownMenuItem(value: 'teacher', child: Text('Prof')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                        if (value == null) return;
                        setSheetState(() {
                          role = value;
                          if (role == 'teacher' && assignedLanguage == null) {
                            assignedLanguage = AdminService.availableLanguages.first;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: _inputDecoration('Statut', Icons.verified_rounded),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Actif')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                        DropdownMenuItem(value: 'blocked', child: Text('Bloqué')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                        if (value == null) return;
                        setSheetState(() => status = value);
                      },
                    ),
                    if (role == 'teacher') ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: assignedLanguage,
                        decoration: _inputDecoration('Langue prise en charge', Icons.language_rounded),
                        items: AdminService.availableLanguages
                            .map(
                              (language) => DropdownMenuItem(
                            value: language,
                            child: Text(language),
                          ),
                        )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                          if (value == null) return;
                          setSheetState(() => assignedLanguage = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Niveaux que ce prof peut prendre en charge',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AdminService.availableLevels.map((level) {
                          final selected = assignedLevels.contains(level);
                          return FilterChip(
                            label: Text(level),
                            selected: selected,
                            selectedColor: AppColors.primarySoft,
                            onSelected: isLoading
                                ? null
                                : (value) {
                              setSheetState(() {
                                if (value) {
                                  assignedLevels.add(level);
                                } else {
                                  assignedLevels.remove(level);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (role == 'student') ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: profileCompleted,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Profil étudiant complété',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Contrôle le passage vers le paiement.'),
                        onChanged: isLoading
                            ? null
                            : (value) => setSheetState(() => profileCompleted = value),
                      ),
                      SwitchListTile(
                        value: isPaid,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Paiement validé',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Permet à l’étudiant d’accéder au dashboard.'),
                        onChanged: isLoading
                            ? null
                            : (value) => setSheetState(() => isPaid = value),
                      ),
                    ],
                    const SizedBox(height: 14),
                    CustomButton(
                      label: isLoading ? 'Enregistrement...' : 'Enregistrer les modifications',
                      icon: Icons.save_rounded,
                      onPressed: isLoading
                          ? null
                          : () async {
                        if (role == 'teacher' && assignedLevels.isEmpty) {
                          _message('Sélectionne au moins un niveau pour ce professeur.');
                          return;
                        }

                        setSheetState(() => isLoading = true);

                        try {
                          await _adminService.updateUserRole(
                            userId: doc.id,
                            role: role,
                          );
                          await _adminService.updateUserStatus(
                            userId: doc.id,
                            status: status,
                          );

                          if (role == 'student') {
                            await _adminService.updateProfileCompleted(
                              userId: doc.id,
                              profileCompleted: profileCompleted,
                            );
                            await _adminService.updateStudentPayment(
                              userId: doc.id,
                              isPaid: isPaid,
                            );
                          }

                          if (role == 'teacher' ||
                              originalRole == 'teacher') {
                            await _adminService.updateTeacherAssignment(
                              userId: doc.id,
                              assignedLanguage: role == 'teacher'
                                  ? assignedLanguage
                                  : null,
                              assignedLevels: role == 'teacher'
                                  ? assignedLevels.toList()
                                  : <String>[],
                            );
                          }

                          if (!sheetContext.mounted) return;

                          Navigator.of(sheetContext).pop();
                          _message('Utilisateur mis à jour.');
                          return;
                        } catch (e) {
                          if (!sheetContext.mounted) return;

                          setSheetState(() => isLoading = false);
                          _message('Erreur : $e');
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Supprimer le document utilisateur',
                      icon: Icons.delete_outline_rounded,
                      outlined: true,
                      foregroundColor: AppColors.danger,
                      onPressed: isLoading
                          ? null
                          : () async {
                        final confirm = await _confirmDelete(sheetContext);
                        if (confirm != true) return;

                        try {
                          await _adminService.deleteUserDocument(doc.id);
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          _message('Document utilisateur supprimé.');
                        } catch (e) {
                          _message('Erreur: $e');
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: cette suppression retire seulement le document Firestore. La suppression totale du compte Auth nécessite Firebase Admin SDK ou Cloud Function.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Tu veux vraiment supprimer ce document utilisateur de Firestore ?',
        ),
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
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
      stream: _adminService.getUsersStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final users = _filterUsers(docs);

        return SingleChildScrollView(
          child: Column(
            children: [
              PremiumHeader(
                badge: 'Gestion des utilisateurs',
                title: 'Comptes et privilèges',
                subtitle:
                'L’admin crée les comptes prof/admin, affecte les profs à une langue et définit plusieurs niveaux autorisés.',
                icon: Icons.people_rounded,
                bottom: CustomButton(
                  label: 'Créer compte prof/admin',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _openCreateStaffDialog,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom ou email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RoleFilter(
                      selected: _selectedRoleFilter,
                      onChanged: (value) => setState(() => _selectedRoleFilter = value),
                    ),
                    const SizedBox(height: 24),
                    SectionTitle('Liste des utilisateurs (${users.length})'),
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
                        text: 'Erreur de chargement. Vérifie les règles Firestore.',
                        danger: true,
                      )
                    else if (users.isEmpty)
                        const _InfoBox(text: 'Aucun utilisateur trouvé.')
                      else
                        ...users.map((doc) {
                          final data = doc.data();
                          final role = _normalizeRole(data['role']);
                          final status = _normalizeStatus(data['status']);
                          final isPaid = data['isPaid'] == true;
                          final assignment = _teacherAssignmentLabel(data);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _openUserActions(doc),
                              tileColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primarySoft,
                                child: Icon(_roleIcon(role), color: AppColors.dark),
                              ),
                              title: Text(
                                AdminService.displayName(data),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dark,
                                ),
                              ),
                              subtitle: Text(
                                '${_roleLabel(role)} • $status • ${AdminService.displayEmail(data)}'
                                    '${role == 'student' ? ' • ${isPaid ? 'Payé' : 'Non payé'}' : ''}'
                                    '${role == 'teacher' ? ' • $assignment' : ''}',
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  height: 1.35,
                                ),
                              ),
                              trailing: const Icon(Icons.tune_rounded),
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

class _CreateStaffDialog extends StatefulWidget {
  final AdminService adminService;

  const _CreateStaffDialog({required this.adminService});

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  String _name = '';
  String _email = '';
  String _password = '';

  String _role = 'teacher';
  String _selectedLanguage = AdminService.availableLanguages.first;
  final Set<String> _selectedLevels = <String>{};
  bool _isLoading = false;
  String? _errorMessage;

  void _cancel() {
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(false);
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;

    final name = _name.trim();
    final email = _email.trim();
    final password = _password.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir le nom, l’email et le mot de passe.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
      });
      return;
    }

    if (_role == 'teacher' && _selectedLevels.isEmpty) {
      setState(() {
        _errorMessage = 'Sélectionnez au moins un niveau pour le professeur.';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[ManageUsers] FIX_V3 creating account');
      await widget.adminService.createStaffAccount(
        name: name,
        email: email,
        password: password,
        role: _role,
        assignedLanguage:
        _role == 'teacher' ? _selectedLanguage : null,
        assignedLevels:
        _role == 'teacher' ? _selectedLevels.toList() : <String>[],
      );

      if (!mounted) return;
      debugPrint('[ManageUsers] FIX_V3 account created, closing dialog');
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message =
          'Cet email existe déjà dans Firebase Authentication. Utilisez un autre email ou supprimez d’abord l’ancien compte.';
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'weak-password':
          message = 'Mot de passe trop faible.';
          break;
        case 'operation-not-allowed':
          message =
          'La création par email et mot de passe est désactivée dans Firebase.';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez la connexion Internet.';
          break;
        default:
          message = e.message ?? 'Erreur lors de la création du compte.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Créer un compte interne',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.dark,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seul l’admin peut créer les comptes professeur et administrateur.',
                  style: TextStyle(color: AppColors.mutedText, height: 1.4),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nom complet',
                  hintText: 'Ex. Ahmed Benali',
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (value) {
                    _name = value;
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Email',
                  hintText: 'prof@academy.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _email = value;
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Mot de passe provisoire',
                  hintText: 'Minimum 6 caractères',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  onChanged: (value) {
                    _password = value;
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _inputDecoration('Rôle', Icons.badge_rounded),
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text('Prof')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrateur'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                      _errorMessage = null;
                    });
                  },
                ),
                if (_role == 'teacher') ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: _inputDecoration(
                      'Langue prise en charge',
                      Icons.language_rounded,
                    ),
                    items: AdminService.availableLanguages
                        .map(
                          (language) => DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      ),
                    )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedLanguage = value;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Niveaux autorisés dans cette langue',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AdminService.availableLevels.map((level) {
                      final selected = _selectedLevels.contains(level);
                      return FilterChip(
                        label: Text(level),
                        selected: selected,
                        selectedColor: AppColors.primarySoft,
                        onSelected: _isLoading
                            ? null
                            : (value) {
                          setState(() {
                            if (value) {
                              _selectedLevels.add(level);
                            } else {
                              _selectedLevels.remove(level);
                            }
                            _errorMessage = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _cancel,
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _createAccount,
            icon: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_isLoading ? 'Création...' : 'Créer'),
          ),
        ],
      ),
    );
  }
}

class _RoleFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{
      'all': 'Tous',
      'student': 'Étudiants',
      'teacher': 'Profs',
      'admin': 'Admins',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: AppColors.primarySoft,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.dark : AppColors.mutedText,
              ),
            ),
          );
        }).toList(),
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
        border: Border.all(
          color: danger ? Colors.red.shade100 : AppColors.border,
        ),
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

String _normalizeRole(dynamic role) {
  final value = _text(role).toLowerCase();
  if (value == 'teacher' || value == 'admin' || value == 'student') {
    return value;
  }
  return 'student';
}

String _roleLabel(String role) {
  switch (role) {
    case 'teacher':
      return 'Prof';
    case 'admin':
      return 'Administrateur';
    case 'student':
    default:
      return 'Étudiant';
  }
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'teacher':
      return Icons.co_present_rounded;
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    case 'student':
    default:
      return Icons.school_rounded;
  }
}

String _normalizeStatus(dynamic status) {
  final value = _text(status).toLowerCase();
  if (value == 'inactive' || value == 'blocked' || value == 'active') {
    return value;
  }
  return 'active';
}

String _teacherAssignmentLabel(Map<String, dynamic> data) {
  final language = _text(data['assignedLanguage']);
  final levels = AdminService.cleanStringList(data['assignedLevels']);

  if (language.isEmpty && levels.isEmpty) {
    return 'Aucune affectation';
  }

  return '${language.isEmpty ? 'Langue non définie' : language} ${levels.isEmpty ? '' : levels.join(', ')}'.trim();
}
