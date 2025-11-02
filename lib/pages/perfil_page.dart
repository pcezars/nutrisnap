// lib/pages/perfil_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  PerfilPage({super.key});

  // Pega o usuário logado
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Função de Logout
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar separada para a tela de Perfil
      appBar: AppBar(
        title: const Text("Perfil"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone do perfil
              const Icon(Icons.person, size: 80),
              const SizedBox(height: 20),
              
              // E-mail do usuário
              Text(
                "Logado como:",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                currentUser?.email ?? 'E-mail não encontrado',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Botão de Sair (agora no lugar certo)
              ElevatedButton(
                onPressed: logout,
                // Deixa o botão vermelho para indicar uma ação de "saída"
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text("Sair"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}