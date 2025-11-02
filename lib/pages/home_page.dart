// lib/pages/home_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NOVO: Import do Storage
import '../components/refeicao_card.dart';
import 'registro_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void irParaPaginaRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroPage()),
    );
  }

  // NOVO: Função para deletar a refeição
  Future<void> _deletarRefeicao(String docId, String imageUrl) async {
    try {
      // 1. Deletar o documento do Firestore
      await FirebaseFirestore.instance.collection('refeicoes').doc(docId).delete();

      // 2. Deletar a imagem do Storage
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriSnap Dashboard"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
          )
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
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

              // NOVO: Envolvendo o Card com o Dismissible
              return Dismissible(
                // 1. Chave ÚNICA: Essencial para o Flutter saber quem é quem
                key: Key(docId),

                // 2. Ação: O que fazer quando o item for arrastado
                onDismissed: (direction) {
                  _deletarRefeicao(docId, imageUrl);
                },

                // 3. O Fundo: O que aparece por trás (o "vermelho")
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                
                // 4. O Filho: O widget que será arrastado
                child: RefeicaoCard(
                  imageUrl: imageUrl,
                  alimentos: data['alimentos'],
                  timestamp: dataRefeicao,
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: irParaPaginaRegistro,
        child: const Icon(Icons.add_a_photo),
        tooltip: "Registrar Refeição",
      ),
    );
  }
}