// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'feed_page.dart'; // Importa a nova página de Feed
import 'perfil_page.dart'; // Importa a nova página de Perfil
import 'registro_page.dart'; // Import crucial

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 

  final List<Widget> _telas = [
    const FeedPage(), 
    PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void irParaPaginaRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistroPage()), // Sem 'const'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: irParaPaginaRegistro,
        child: const Icon(Icons.add_a_photo),
        tooltip: "Registrar Refeição",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}