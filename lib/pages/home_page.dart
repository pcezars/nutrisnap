import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Função de Logout
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriSnap Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
          )
        ],
      ),
      body: const Center(
        child: Text("Você está LOGADO! Esta é a Home."),
      ),
    );
  }
}