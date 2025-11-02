// lib/pages/favoritos_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _favoritosStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Prepara o Stream para ler a subcoleção de favoritos
    if (currentUser != null) {
      _favoritosStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('favoritos')
          .snapshots();
    }
  }

  // 2. A função "Mágica" de 1-Clique
  Future<void> _adicionarFavoritoAoLog(Map<String, dynamic> favoritoData) async {
    if (currentUser == null) return;

    setState(() { _isLoading = true; });

    try {
      // 3. Adiciona os dados do favorito à coleção principal 'refeicoes'
      await FirebaseFirestore.instance.collection('refeicoes').add({
        'userId': currentUser!.uid,
        'emailUsuario': currentUser!.email,
        
        // Dados copiados do favorito
        'alimentosLista': favoritoData['alimentosLista'],
        'totalCalorias': favoritoData['totalCalorias'],
        'totalProteinas': favoritoData['totalProteinas'],
        'totalCarboidratos': favoritoData['totalCarboidratos'],
        'totalGorduras': favoritoData['totalGorduras'],
        'imageUrl': favoritoData['imageUrl'],
        
        // O Timestamp DE AGORA (para aparecer no feed de 'Hoje')
        'timestamp': FieldValue.serverTimestamp(), 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição adicionada ao seu dia! 💪")),
        );
        // 4. Volta para a FeedPage
        Navigator.of(context).pop();
      }

    } catch (e) {
      print("Erro ao adicionar favorito ao log: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar: $e")),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  // 5. Função para apagar um favorito (Bónus de UX)
  Future<void> _deletarFavorito(String docId) async {
     await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('favoritos')
          .doc(docId)
          .delete();
      
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Favorito removido.")),
        );
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar dos Favoritos"),
      ),
      // 6. O StreamBuilder que lê os favoritos
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) // Mostra loading geral ao adicionar
        : StreamBuilder<QuerySnapshot>(
            stream: _favoritosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Erro: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Você ainda não salvou nenhuma refeição favorita.\nClique na estrela (★) no seu feed!",
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // 7. Temos favoritos! Vamos listá-los.
              final List<DocumentSnapshot> documentos = snapshot.data!.docs;
              return ListView.builder(
                itemCount: documentos.length,
                itemBuilder: (context, index) {
                  final data = documentos[index].data() as Map<String, dynamic>;
                  final docId = documentos[index].id;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: ListTile(
                      // O Ícone de Estrela
                      leading: Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
                      // O Nome do Favorito
                      title: Text(data['nome'] ?? 'Refeição Favorita'),
                      // O Resumo de Calorias
                      subtitle: Text("Aprox. ${data['totalCalorias']} Kcal"),
                      // Ação de Deletar (arrastar para o lado)
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deletarFavorito(docId),
                        tooltip: "Remover dos Favoritos",
                      ),
                      // A AÇÃO PRINCIPAL: Adicionar ao log de hoje
                      onTap: () {
                        _adicionarFavoritoAoLog(data);
                      },
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}