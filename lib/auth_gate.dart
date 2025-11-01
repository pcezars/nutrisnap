import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se não houver dados (usuário null), mostre o Login
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Se houver dados (usuário logado), mostre a Home
        return const HomePage();
      },
    );
  }
}