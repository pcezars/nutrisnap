// lib/pages/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'feed_page.dart'; 
import 'perfil_page.dart'; 
import 'registro_page.dart';
import 'favoritos_page.dart'; 
import 'adicao_rapida_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  
  // NOVO: O estado dos favoritos agora vive aqui, na "mãe"
  Set<String> _favoritosImageUrls = {};
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // NOVO: A lista de telas agora é construída no 'initState'
  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    // 1. Carrega os favoritos assim que a Home é criada
    _carregarFavoritos();
    
    // 2. Constrói a lista de telas, passando o estado e a função
    _telas = [
      FeedPage(
        favoritosImageUrls: _favoritosImageUrls,
        onToggleFavorito: _toggleFavorito, // Passa a nova função
      ),
      PerfilPage(),
    ];
  }
  
  // NOVO: Função que carrega os favoritos (movida do FeedPage)
  Future<void> _carregarFavoritos() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('favoritos')
          .get();
      
      final urls = snapshot.docs.map((doc) => doc.data()['imageUrl'] as String).toSet();
      
      if (mounted) {
        setState(() {
          _favoritosImageUrls = urls;
          // Reconstrói a _telas com o novo set
          _telas[0] = FeedPage(
            favoritosImageUrls: _favoritosImageUrls,
            onToggleFavorito: _toggleFavorito,
          );
        });
      }
    } catch (e) {
      print("Erro ao carregar favoritos: $e");
    }
  }

  // NOVO: Função de toggle (movida do FeedPage)
  Future<void> _toggleFavorito(Map<String, dynamic> refeicaoData) async {
    if (currentUser == null) return;

    final String imageUrl = refeicaoData['imageUrl'];

    // Lógica de "Unfavorite"
    if (_favoritosImageUrls.contains(imageUrl)) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('usuarios').doc(currentUser!.uid).collection('favoritos')
            .where('imageUrl', isEqualTo: imageUrl)
            .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        if (mounted) {
          setState(() {
            _favoritosImageUrls.remove(imageUrl); // Atualiza o estado local
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Refeição removida dos Favoritos.")),
          );
        }
      } catch (e) { print("Erro ao desfavoritar: $e"); }
      return; 
    }

    // Lógica de "Favorite"
    try {
      refeicaoData.remove('timestamp');
      refeicaoData.remove('userId'); 
      refeicaoData.remove('emailUsuario');
      final String nomeFavorito = (refeicaoData['alimentosLista'] as List)
          .map((item) => item['alimento'])
          .join(', ');
      await FirebaseFirestore.instance
          .collection('usuarios').doc(currentUser!.uid).collection('favoritos')
          .add({'nome': nomeFavorito, ...refeicaoData});
      if (mounted) {
        setState(() {
          _favoritosImageUrls.add(imageUrl); // Atualiza o estado local
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição salva nos Favoritos! 🌟")),
        );
      }
    } catch (e) { print("Erro ao favoritar: $e"); }
  }


  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  // MODIFICADO: A "mágica" está aqui. Usamos .then()
  void _mostrarOpcoesDeAdicao() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Analisar com Câmera'),
                onTap: () {
                  Navigator.of(context).pop(); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistroPage()),
                  // NOVO: Quando voltarmos da RegistroPage, recarrega os favoritos
                  ).then((_) => _carregarFavoritos()); 
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Adicionar dos Favoritos'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritosPage()),
                  // NOVO: Quando voltarmos da FavoritosPage, recarrega os favoritos
                  ).then((_) => _carregarFavoritos());
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Adição Rápida Manual'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdicaoRapidaPage()),
                  // NOVO: Quando voltarmos da AdicaoRapidaPage, recarrega os favoritos
                  ).then((_) => _carregarFavoritos());
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary, 
      ),
    );
  }
}