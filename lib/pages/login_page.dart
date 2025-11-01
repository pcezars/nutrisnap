import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20).copyWith(top: 40),
          child: Icon(
            Icons.food_bank_rounded,
            color: Colors.green,
            size: 100,
          ),
        );
      },
      subtitleBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            action == AuthAction.signIn
                ? 'Bem-vindo ao NutriSnap! Faça o login.'
                : 'Crie sua conta no NutriSnap!',
          ),
        );
      },
    );
  }
}