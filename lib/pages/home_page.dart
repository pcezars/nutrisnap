import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'registro_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Função de Logout
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // Função para navegar para a página de registro
  void irParaPaginaRegistro() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const RegistroPage()),
    // );
    
    // Por enquanto, vamos apenas mostrar um print
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegistroPage()),
  );
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
      
      // 2. Adicione o Botão de Ação Flutuante (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: irParaPaginaRegistro,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_a_photo),
        tooltip: "Registrar Refeição",
      ),
    );
  }
}