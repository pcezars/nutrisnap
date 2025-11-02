// lib/pages/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'feed_page.dart'; 
import 'perfil_page.dart'; 
import 'registro_page.dart';
import 'favoritos_page.dart'; 
import 'adicao_rapida_page.dart';
import 'progresso_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  Set<String> _favoritosImageUrls = {};
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    _carregarFavoritos();
    
    _telas = [
      FeedPage(
        favoritosImageUrls: _favoritosImageUrls,
        onToggleFavorito: _toggleFavorito,
      ),
      const ProgressoPage(), 
      const PerfilPage(),
    ];
  }
  
  Future<void> _carregarFavoritos() async {
    // (A função _carregarFavoritos continua igual)
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios').doc(currentUser!.uid).collection('favoritos').get();
      final urls = snapshot.docs.map((doc) => doc.data()['imageUrl'] as String).toSet();
      if (mounted) {
        setState(() {
          _favoritosImageUrls = urls;
          _telas[0] = FeedPage(
            favoritosImageUrls: _favoritosImageUrls,
            onToggleFavorito: _toggleFavorito,
          );
        });
      }
    } catch (e) { print("Erro ao carregar favoritos: $e"); }
  }

  Future<void> _toggleFavorito(Map<String, dynamic> refeicaoData) async {
    // (A função _toggleFavorito continua igual)
    if (currentUser == null) return;
    final String imageUrl = refeicaoData['imageUrl'];
    if (_favoritosImageUrls.contains(imageUrl)) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('usuarios').doc(currentUser!.uid).collection('favoritos')
            .where('imageUrl', isEqualTo: imageUrl).get();
        for (final doc in query.docs) { await doc.reference.delete(); }
        if (mounted) {
          setState(() { _favoritosImageUrls.remove(imageUrl); });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Refeição removida dos Favoritos.")),
          );
        }
      } catch (e) { print("Erro ao desfavoritar: $e"); }
      return; 
    }
    try {
      refeicaoData.remove('timestamp');
      refeicaoData.remove('userId'); 
      refeicaoData.remove('emailUsuario');
      final String nomeFavorito = (refeicaoData['alimentosLista'] as List)
          .map((item) => item['alimento']).join(', ');
      await FirebaseFirestore.instance
          .collection('usuarios').doc(currentUser!.uid).collection('favoritos')
          .add({'nome': nomeFavorito, ...refeicaoData});
      if (mounted) {
        setState(() { _favoritosImageUrls.add(imageUrl); });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição salva nos Favoritos! 🌟")),
        );
      }
    } catch (e) { print("Erro ao favoritar: $e"); }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  void _mostrarOpcoesDeAdicao() {
    // (A função _mostrarOpcoesDeAdicao continua igual)
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt), title: const Text('Analisar com Câmera'),
                onTap: () {
                  Navigator.of(context).pop(); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroPage())).then((_) => _carregarFavoritos()); 
                },
              ),
              ListTile(
                leading: const Icon(Icons.star), title: const Text('Adicionar dos Favoritos'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritosPage())).then((_) => _carregarFavoritos());
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note), title: const Text('Adição Rápida Manual'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdicaoRapidaPage())).then((_) => _carregarFavoritos());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_selectedIndex],
      
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarOpcoesDeAdicao,
        child: const Icon(Icons.add), 
        tooltip: "Adicionar Refeição",
      ),
      // REVERTIDO: FAB de volta ao centro
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, 
      
      // REVERTIDO: Voltamos ao 'BottomAppBar' com 4 "espaços"
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Aba 1: Feed
            _buildTabItem(icon: Icons.home, label: 'Feed', index: 0),
            
            // Aba 2: Progresso
            _buildTabItem(icon: Icons.show_chart, label: 'Progresso', index: 1),
            
            // O Espaçador Vazio
            const SizedBox(width: 40), 
            
            // Aba 3: Perfil
            _buildTabItem(icon: Icons.person, label: 'Perfil', index: 2),
          ],
        ),
      ),
    );
  }

  // (A função _buildTabItem continua 100% igual)
  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: label,
      onPressed: () => _onItemTapped(index),
    );
  }
}