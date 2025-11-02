// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'feed_page.dart'; // Importa a nova página de Feed
import 'perfil_page.dart'; // Importa a nova página de Perfil
import 'registro_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. Variável para controlar qual aba está selecionada
  int _selectedIndex = 0; 

  // 2. Lista de telas que o BottomNav vai controlar
  final List<Widget> _telas = [
    const FeedPage(), // Posição 0
    PerfilPage(),   // Posição 1
  ];

  // 3. Função chamada quando o usuário toca em uma aba
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 4. Função de navegação (FAB)
  void irParaPaginaRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 5. O body agora mostra a tela selecionada (Feed ou Perfil)
      body: _telas[_selectedIndex],

      // 6. O Botão Flutuante (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: irParaPaginaRegistro,
        child: const Icon(Icons.add_a_photo),
        tooltip: "Registrar Refeição",
      ),
      // 7. Centraliza o FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 8. A Barra de Navegação Inferior
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Usa a cor do tema
      ),
    );
  }
}