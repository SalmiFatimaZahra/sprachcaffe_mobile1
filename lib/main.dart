import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


import 'core/app_theme.dart';
import 'features/auth/auth_wrapper.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signOut();

  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}