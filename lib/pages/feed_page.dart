// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../components/refeicao_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Função para deletar a refeição
  Future<void> _deletarRefeicao(String docId, String imageUrl) async {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('refeicoes')
          .where('userId', isEqualTo: currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      
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
              "Nenhuma refeição registrada.\nClique no '+' para adicionar uma!",
              textAlign: TextAlign.center,
            ),
          );
        }

        final List<DocumentSnapshot> documentos = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> data =
                documentos[index].data() as Map<String, dynamic>;
            
            final Timestamp timestamp = data['timestamp'];
            final DateTime dataRefeicao = timestamp.toDate();
            
            final String docId = documentos[index].id;
            final String imageUrl = data['imageUrl'];

            return Dismissible(
              key: Key(docId),
              onDismissed: (direction) {
                _deletarRefeicao(docId, imageUrl);
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: RefeicaoCard(
                imageUrl: imageUrl,
                alimentos: data['alimentos'],
                timestamp: dataRefeicao,
              ),
            );
          },
        );
      },
    );
  }
}