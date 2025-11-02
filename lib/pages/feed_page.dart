// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../components/refeicao_card.dart';
import 'chat_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> _perfilStream;
  late Stream<QuerySnapshot> _refeicoesStream;
  
  // NOVO: Um Set para guardar as URLs das imagens favoritas
  Set<String> _favoritosImageUrls = {};

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _perfilStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .snapshots();

      final DateTime agora = DateTime.now();
      final DateTime inicioDoDia = DateTime(agora.year, agora.month, agora.day, 0, 0, 0);
      final DateTime fimDoDia = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

      _refeicoesStream = FirebaseFirestore.instance
          .collection('refeicoes')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('timestamp', isGreaterThanOrEqualTo: inicioDoDia)
          .where('timestamp', isLessThanOrEqualTo: fimDoDia)
          .orderBy('timestamp', descending: true)
          .snapshots();
          
      // NOVO: Carrega os favoritos uma vez
      _carregarFavoritos();
    }
  }
  
  // NOVO: Função que carrega os favoritos na inicialização
  Future<void> _carregarFavoritos() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('favoritos')
          .get();
      
      // Criamos um Set com todas as imageUrls dos favoritos
      final urls = snapshot.docs.map((doc) => doc.data()['imageUrl'] as String).toSet();
      
      if (mounted) {
        setState(() {
          _favoritosImageUrls = urls;
        });
      }
    } catch (e) {
      print("Erro ao carregar favoritos: $e");
    }
  }

  Future<void> _deletarRefeicao(String docId, String imageUrl) async {
    // (Função de deletar - sem mudanças)
    try {
      await FirebaseFirestore.instance.collection('refeicoes').doc(docId).delete();
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição deletada com sucesso!")),
        );
      }
    } catch (e) {
      print("Erro ao deletar refeição: $e");
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao deletar: $e")),
        );
      }
    }
  }

  // MODIFICADO: A lógica de favoritar agora atualiza o estado local
  Future<void> _favoritarRefeicao(Map<String, dynamic> refeicaoData) async {
    if (currentUser == null) return;

    final String imageUrl = refeicaoData['imageUrl'];

    // Lógica de "Unfavorite" (se já for favorito, remove)
    if (_favoritosImageUrls.contains(imageUrl)) {
      try {
        // Encontra o documento favorito pela imageUrl
        final query = await FirebaseFirestore.instance
            .collection('usuarios').doc(currentUser!.uid).collection('favoritos')
            .where('imageUrl', isEqualTo: imageUrl)
            .get();
        
        // Deleta todos os docs encontrados (deve ser só 1)
        for (final doc in query.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          setState(() {
            _favoritosImageUrls.remove(imageUrl); // Remove do estado local
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Refeição removida dos Favoritos.")),
          );
        }
      } catch (e) {
        print("Erro ao desfavoritar: $e");
      }
      return; // Para a execução
    }

    // Lógica de "Favorite" (se não for favorito, adiciona)
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
          _favoritosImageUrls.add(imageUrl); // Adiciona ao estado local
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição salva nos Favoritos! 🌟")),
        );
      }
    } catch (e) {
      print("Erro ao favoritar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao favoritar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // (O build do StreamBuilder do Perfil continua igual)
    if (currentUser == null) { return const Center(child: Text("Usuário não encontrado.")); }
    return StreamBuilder<DocumentSnapshot>(
      stream: _perfilStream,
      builder: (context, perfilSnapshot) {
        if (perfilSnapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        if (!perfilSnapshot.hasData || !perfilSnapshot.data!.exists) { return const Center(child: Text("Perfil não encontrado.")); }
        final perfilData = perfilSnapshot.data!.data() as Map<String, dynamic>;
        final int metaCal = (perfilData['metaCalorias'] ?? 0).round();
        final int metaProt = (perfilData['metaProteinas'] ?? 0).round();
        final int metaCarb = (perfilData['metaCarboidratos'] ?? 0).round();
        final int metaGord = (perfilData['metaGorduras'] ?? 0).round();

        // (O StreamBuilder das Refeições continua igual)
        return StreamBuilder<QuerySnapshot>(
          stream: _refeicoesStream,
          builder: (context, refeicoesSnapshot) {
            if (refeicoesSnapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
            if (refeicoesSnapshot.hasError) { return Center(child: Text("Erro ao carregar refeições: ${refeicoesSnapshot.error}")); }

            int consumidoCal = 0, consumidoProt = 0, consumidoCarb = 0, consumidoGord = 0;
            final List<DocumentSnapshot> documentos = refeicoesSnapshot.data?.docs ?? [];
            for (var doc in documentos) {
              final data = doc.data() as Map<String, dynamic>;
              consumidoCal += (data['totalCalorias'] ?? 0) as int;
              consumidoProt += (data['totalProteinas'] ?? 0) as int;
              consumidoCarb += (data['totalCarboidratos'] ?? 0) as int;
              consumidoGord += (data['totalGorduras'] ?? 0) as int;
            }

            // (A 'Column' principal continua igual)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDashboard(
                  metaCal, consumidoCal, metaProt, consumidoProt,
                  metaCarb, consumidoCarb, metaGord, consumidoGord
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: Text("Refeições de Hoje", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: documentos.isEmpty
                      ? const Center(
                          child: Text("Nenhuma refeição registrada hoje.\nClique no '+' para adicionar uma!", textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: documentos.length,
                          itemBuilder: (context, index) {
                            final data = documentos[index].data() as Map<String, dynamic>;
                            final timestamp = (data['timestamp'] as Timestamp).toDate();
                            final docId = documentos[index].id;
                            final imageUrl = data['imageUrl'];
                            
                            // MODIFICADO: Verificamos o estado no nosso Set local
                            final bool isFavorito = _favoritosImageUrls.contains(imageUrl);

                            return Dismissible(
                              key: Key(docId),
                              onDismissed: (direction) { _deletarRefeicao(docId, imageUrl); },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: RefeicaoCard(
                                imageUrl: imageUrl,
                                timestamp: timestamp,
                                alimentosLista: data['alimentosLista'] ?? [],
                                totalCalorias: data['totalCalorias'] ?? 0,
                                totalProteinas: data['totalProteinas'] ?? 0,
                                totalCarboidratos: data['totalCarboidratos'] ?? 0,
                                totalGorduras: data['totalGorduras'] ?? 0,
                                isFavorito: isFavorito, // Passa o estado
                                onFavoritePressed: () {
                                  _favoritarRefeicao(data); // Chama a função de toggle
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // (Todos os widgets _build... continuam iguais)
  Widget _buildDashboard(int metaCal, int consumidoCal, int metaProt, int consumidoProt, int metaCarb, int consumidoCarb, int metaGord, int consumidoGord) {
    int restanteCal = metaCal - consumidoCal;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(restanteCal.toString(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const Text("Calorias Restantes", style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildMacroResumo("Consumido", consumidoCal, "Kcal"), const Text("=", style: TextStyle(fontSize: 20)), _buildMacroResumo("Meta", metaCal, "Kcal")]),
          const Divider(height: 24),
          TextButton.icon(
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text("Perguntar ao Nutri Coach"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    metaCalorias: metaCal, metaProteinas: metaProt, metaCarboidratos: metaCarb, metaGorduras: metaGord,
                    consumidoCalorias: consumidoCal, consumidoProteinas: consumidoProt, consumidoCarboidratos: consumidoCarb, consumidoGorduras: consumidoGord,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroProgresso("Proteínas", consumidoProt, metaProt, "g"),
              _buildMacroProgresso("Carbos", consumidoCarb, metaCarb, "g"),
              _buildMacroProgresso("Gorduras", consumidoGord, metaGord, "g"),
            ],
          ),
        ],
      ),
    );
  }
  Column _buildMacroResumo(String label, int value, String sufixo) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text("$label ($sufixo)", style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
  Column _buildMacroProgresso(String label, int consumido, int meta, String sufixo) {
    double progresso = (meta > 0) ? (consumido / meta) : 0.0;
    if (progresso > 1.0) progresso = 1.0; 
    return Column(
      children: [
        SizedBox(
          height: 80, width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(value: progresso, strokeWidth: 8, backgroundColor: Colors.grey[200], color: Theme.of(context).colorScheme.primary),
              Center(child: Text("${consumido}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}