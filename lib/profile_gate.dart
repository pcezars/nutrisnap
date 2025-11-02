// lib/profile_gate.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';

class ProfileGate extends StatelessWidget {
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Se por algum motivo o usuário for nulo, não deveríamos estar aqui.
    if (currentUser == null) {
      // (O AuthGate já nos protege disso, mas é uma boa prática)
      return const Scaffold(body: Center(child: Text("Erro: Usuário nulo")));
    }

    return StreamBuilder<DocumentSnapshot>(
      // 1. Ouve o documento do usuário na coleção 'usuarios'
      stream: FirebaseFirestore.instance
          .collection('usuarios') // NOVO: Nossa coleção de perfis
          .doc(currentUser.uid)
          .snapshots(),
      
      builder: (context, snapshot) {
        // 2. Enquanto espera, mostre um loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 3. Se o documento (perfil) NÃO EXISTE, mande para o Onboarding
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const OnboardingPage();
        }

        // 4. Se o documento EXISTE, o usuário já completou o onboarding!
        return const HomePage();
      },
    );
  }
}